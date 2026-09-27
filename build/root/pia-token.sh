# Appended to the base image's /usr/local/bin/tools.sh by the Dockerfile, so
# this definition replaces upstream's pia_generate_token when tools.sh is
# sourced. Upstream calls the legacy gtoken endpoint, which stopped answering
# in September 2026, and returns on the first failure so its fallback URL and
# retries never run. /api/client/v2/token is the route PIA's own
# manual-connections scripts use.
function pia_generate_token() {

	local retry_count=12
	local retry_wait_secs=10
	local token_json_response

	while [[ "${retry_count}" -gt "0" ]]; do

		# --form-string, not --form: --form treats a leading @ or < and a
		# ;type= suffix in the value as syntax, which a password may contain
		token_json_response=$(curl --silent --max-time 30 --request POST \
			--form-string "username=${VPN_USER}" \
			--form-string "password=${VPN_PASS}" \
			"https://www.privateinternetaccess.com/api/client/v2/token")

		PIA_GENERATE_TOKEN=$(echo "${token_json_response}" | jq -r '.token // empty' 2> /dev/null)

		if [[ -n "${PIA_GENERATE_TOKEN}" ]]; then
			echo "[info] Successfully generated PIA token for wireguard"
			return 0
		fi

		retry_count=$((retry_count-1))
		echo "[warn] Failed to generate PIA token, ${retry_count} retries left, retrying in ${retry_wait_secs} secs..."
		sleep "${retry_wait_secs}"s & wait $!

	done

	return 1

}
