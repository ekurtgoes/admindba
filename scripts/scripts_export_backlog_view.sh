#!/usr/bin/env bash
set -euo pipefail

# Exporta ProjectV2 a Markdown con filtros tipo "vista"
#
# Uso:
#   ./scripts/export_backlog_view.sh
#   ./scripts/export_backlog_view.sh ekurtgoes 2 backlog-view.md "Status=Backlog"
#   ./scripts/export_backlog_view.sh ekurtgoes 2 backlog-view.md "Status=Backlog" "Priority=High"
#
# Requisitos:
#   - gh CLI instalado y autenticado (gh auth login)
#   - jq instalado
#   - token con permisos de Projects si aplica: export GH_TOKEN=...

OWNER="${1:-ekurtgoes}"
PROJECT_NUMBER="${2:-2}"
OUT_MD="${3:-backlog-view.md}"
shift $(( $# >= 3 ? 3 : $# )) || true
FILTERS=( "$@" )  # ej: "Status=Backlog" "Priority=High"

TMP_JSON="$(mktemp)"
TMP_QUERY="$(mktemp)"
TMP_FILTER_JSON="$(mktemp)"

cleanup() {
  rm -f "$TMP_JSON" "$TMP_QUERY" "$TMP_FILTER_JSON"
}
trap cleanup EXIT

cat > "$TMP_QUERY" <<'GRAPHQL'
query($login:String!, $number:Int!, $after:String) {
  user(login: $login) {
    projectV2(number: $number) {
      title
      number
      url
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          content {
            __typename
            ... on Issue {
              title
              number
              url
              state
            }
            ... on PullRequest {
              title
              number
              url
              state
            }
            ... on DraftIssue {
              title
            }
          }
          fieldValues(first: 50) {
            nodes {
              __typename
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
              ... on ProjectV2ItemFieldTextValue {
                text
                field { ... on ProjectV2FieldCommon { name } }
              }
              ... on ProjectV2ItemFieldDateValue {
                date
                field { ... on ProjectV2FieldCommon { name } }
              }
            }
          }
        }
      }
    }
  }
}
GRAPHQL

# Convierte filtros "Campo=Valor" -> JSON [{"field":"Status","value":"Backlog"}, ...]
printf '%s\n' "${FILTERS[@]}" | jq -R -s '
  split("\n")
  | map(select(length>0))
  | map(
      capture("^(?<field>[^=]+)=(?<value>.*)$")
      | {field: .field, value: .value}
    )
' > "$TMP_FILTER_JSON"

echo "⏳ Descargando items del proyecto user=${OWNER} number=${PROJECT_NUMBER}..."

# Paginación
FIRST_PAGE=true
AFTER="null"

while :; do
  if [ "$AFTER" = "null" ]; then
    PAGE_JSON="$(gh api graphql -f query="@${TMP_QUERY}" -F login="${OWNER}" -F number="${PROJECT_NUMBER}")"
  else
    PAGE_JSON="$(gh api graphql -f query="@${TMP_QUERY}" -F login="${OWNER}" -F number="${PROJECT_NUMBER}" -F after="${AFTER}")"
  fi

  if $FIRST_PAGE; then
    echo "$PAGE_JSON" > "$TMP_JSON"
    FIRST_PAGE=false
  else
    # Merge nodes
    jq -s '
      .[0] as $acc
      | .[1] as $new
      | $acc
      | .data.user.projectV2.items.nodes += $new.data.user.projectV2.items.nodes
      | .data.user.projectV2.items.pageInfo = $new.data.user.projectV2.items.pageInfo
    ' "$TMP_JSON" <(echo "$PAGE_JSON") > "${TMP_JSON}.new"
    mv "${TMP_JSON}.new" "$TMP_JSON"
  fi

  HAS_NEXT="$(echo "$PAGE_JSON" | jq -r '.data.user.projectV2.items.pageInfo.hasNextPage // false')"
  if [ "$HAS_NEXT" != "true" ]; then
    break
  fi
  AFTER="$(echo "$PAGE_JSON" | jq -r '.data.user.projectV2.items.pageInfo.endCursor')"
done

jq -r --argjson filters "$(cat "$TMP_FILTER_JSON")" '
  def normalize:
    tostring | ascii_downcase | gsub("^\\s+|\\s+$";"");

  def kvpairs:
    .fieldValues.nodes
    | map(
        if .__typename=="ProjectV2ItemFieldSingleSelectValue" then
          {k: (.field.name // ""), v: (.name // "")}
        elif .__typename=="ProjectV2ItemFieldTextValue" then
          {k: (.field.name // ""), v: (.text // "")}
        elif .__typename=="ProjectV2ItemFieldDateValue" then
          {k: (.field.name // ""), v: (.date // "")}
        else empty end
      );

  def passes_filters($filters):
    if ($filters | length) == 0 then true
    else
      (kvpairs) as $pairs
      | [ $filters[] as $f
          | any($pairs[]; ((.k|normalize)==($f.field|normalize)) and ((.v|normalize)==($f.value|normalize)))
        ]
      | all
    end;

  .data.user.projectV2 as $p
  | if $p == null then
      "ERROR: No se encontró el proyecto para ese owner/number."
    else
      "# Backlog (vista filtrada): \($p.title)\n\n"
      + "- Project URL: \($p.url)\n"
      + "- Project Number: \($p.number)\n"
      + (if ($filters|length)>0 then "- Filtros: " + ($filters | map("\(.field)=\(.value)") | join(", ")) + "\n" else "- Filtros: (ninguno)\n" end)
      + "\n## Items\n\n"
      + (
        $p.items.nodes
        | map(select(passes_filters($filters)))
        | if length==0 then
            ["_Sin resultados con esos filtros_"] | join("\n")
          else
            map(
              (
                if .content == null then
                  "- [Sin contenido visible]"
                elif .content.__typename == "Issue" or .content.__typename == "PullRequest" then
                  "- [\(.content.title)](\(.content.url))"
                  + " (`\(.content.__typename) #\(.content.number)` · \(.content.state))"
                elif .content.__typename == "DraftIssue" then
                  "- \(.content.title) (`DraftIssue`)"
                else
                  "- [Tipo no contemplado]"
                end
              )
              + (
                (kvpairs | map("\(.k): \(.v)"))
                | if length>0 then "\n  - " + join("\n  - ") else "" end
              )
            )
            | join("\n\n")
          end
      )
    end
' "$TMP_JSON" > "$OUT_MD"

echo "✅ Archivo generado: $OUT_MD"