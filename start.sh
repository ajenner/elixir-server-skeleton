function to_int {
  local -i num="10#${1}"
  echo "${num}"
}

function do_it {
  if hash mix 2>/dev/null; then
    local port="$1"
    local -i portNum=$(to_int "${port}" 2>/dev/null)
    if (( $portNum < 1 || $portNum > 65535 )) ; then
      echo "${port} is not a valid port" 1>&2
      return
    fi
    export PORT_NUM=$1
    mix run --no-halt
  else
    echo "You don't have the right bits and pieces installed. Read the readme."
  fi
}

do_it $1
