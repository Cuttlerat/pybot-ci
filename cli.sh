#!/usr/bin/env bash

FILES=$(xargs <.encrypt-files)
PASSFILE=".encrypt-pass"

function askpass {
  read -sp "Password: " PASSWORD
  echo "$PASSWORD" > $PASSFILE
  echo 
}

function encrypt {
  if [[ -f .encrypted ]]; then
    echo "$(tput setaf 1)Already encrypted"
  else
    for FILE in ${FILES}; do
      gpg2 --cipher-algo AES256 --passphrase $(cat "$PASSFILE") --batch -c "${FILE}" && rm "${FILE}" || exit 1
    done && touch .encrypted
    echo "Encrypted"
  fi
}

function decrypt {
  if [[ -f .encrypted ]]; then
    for FILE in ${FILES}; do
      gpg2 --passphrase $(cat "$PASSFILE") --batch --output "${FILE}" -d "${FILE}.gpg" && rm "${FILE}.gpg" || exit 1
    done
    rm .encrypted
    echo "Decrypted"
  else
      echo "$(tput setaf 1)Not encrypted"
  fi
}

function push {
  git add .
  shift
  [[ $* == "" ]] && COMMIT_MESSAGE="autocommit" || COMMIT_MESSAGE="$*"
  git commit -m "${COMMIT_MESSAGE}"
  git push origin `git symbolic-ref --short HEAD`
}

if [ ! -f $PASSFILE ]; then
  askpass
fi

case $1 in
  set-password)
    askpass
    ;;
  encrypt)
    encrypt
    ;;
  decrypt)
    decrypt
    ;;
  push)
    encrypt
    push $@
    decrypt
    ;;
  *)
    echo "Unknown command"
    ;;
esac
