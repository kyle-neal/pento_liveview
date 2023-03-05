#!/bin/bash

EX=""
ERL=""

unameOut="$(uname -s)"
SYSTEMD="--enable-systemd"
if [[ -z $(file /sbin/init | grep "systemd") ]]; then
    echo "DISABLING SYSTEMD!!!!"
    SYSTEMD=""
fi

case "${unameOut}" in
    Linux*)     export KERL_CONFIGURE_OPTIONS="--enable-smp-support --without-odbc --enable-kernel-poll --without-javac --enable-threads --enable-hipe --with-ssl ${SYSTEMD}";;
    Darwin*)    export KERL_CONFIGURE_OPTIONS="--enable-smp-support --without-odbc --enable-kernel-poll --without-javac --enable-threads --enable-hipe --with-ssl=$(brew --prefix openssl@1.1)";;
    *)          echo "UNKNOWN SYSTEM ${unameOut}" && exit 1
esac

echo "Bootstrapping asdf on a ${unameOut} machine, with kerl options: ${KERL_CONFIGURE_OPTIONS}"

function asdf_installed() {
  if [[ -d "${HOME}/.asdf" ]]; then
    source_asdf;
    return 1;
  else
    return 0;
  fi;
}

function asdf_install() {
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1
  DONE=$(grep asdf.sh ${HOME}/.bashrc | wc -l | awk '{print $1}');
  if [[ "${DONE}" = "0" ]]; then
    echo ". \${HOME}/.asdf/asdf.sh" >> ${HOME}/.bashrc
  fi;
}

function asdf_install_plugins() {
  asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git ;
  asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git ;
  echo "Installed Plugins:";
  asdf plugin list;
}

function asdf_get_versions() {
  EX=$(cat ./.tool-versions | grep elixir | awk '{print $2}');
  ERL=$(cat ./.tool-versions | grep erlang | awk '{print $2}');
}

function asdf_install_versions() {
  if [[ "${EX}" != "" ]]; then
    INSTALLED=$(asdf list elixir | grep "${EX}");
    if [[ "${INSTALLED}" = "" ]]; then
      echo "Installing Elixir ${EX}";
      asdf install elixir ${EX} ;
    else
      echo "Elixir ${EX} already installed";
    fi;
  fi;
  if [[ "${ERL}" != "" ]]; then
    INSTALLED=$(asdf list erlang | grep "${ERL}");
    if [[ "${INSTALLED}" = "" ]]; then
      echo "Installing Erlang ${ERL}";
      asdf install erlang ${ERL} ;
    else
      echo "Erlang ${ERL} already installed";
    fi;
  fi;
}

function asdf_set_versions() {
  if [[ "${EX}" != "" ]]; then
    asdf local elixir ${EX} ;
  fi;
  if [[ "${ERL}" != "" ]]; then
    asdf local erlang ${ERL} ;
  fi;
}

function asdf_install_deps() {
  if [[ "${EX}" != "" ]]; then
    mix local.hex --force
    mix local.rebar --force
  fi;
}

function source_asdf() {
  . $HOME/.asdf/asdf.sh
}

asdf_installed
INSTALLED=$?;
if [[ ${INSTALLED} = 0 ]]; then
  echo "Installing asdf";
  asdf_install || exit 1;
  source_asdf || exit 1;
  echo "Installing Erlang and Elixir plugins";
  asdf_install_plugins || exit 1;
else
  echo "asdf already installed";
fi;
echo "Getting required versions"
asdf_get_versions || exit 1;
echo "Installing required versions"
asdf_install_versions || exit 1;
echo "Setting local versions";
asdf_set_versions || exit 1;
echo "Installing hex+rebar deps";
asdf_install_deps || exit 1;
