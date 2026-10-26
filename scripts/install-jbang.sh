#!/bin/bash
# Sourced by each Local task. Installs JBang + Camel CLI 4.22.0 if missing.
# Idempotent: si ya estan instalados no baja nada.
# Uso manual:  source scripts/install-jbang.sh && camel version
export PATH="${HOME}/.jbang/bin:${PATH}"
if ! command -v camel >/dev/null 2>&1 || ! camel version 2>/dev/null | grep -q 4.22.0; then
  echo "Instalando JBang y Camel CLI 4.22.0..."
  command -v jbang >/dev/null 2>&1 || { curl -Ls https://sh.jbang.dev | bash -s -; export PATH="${HOME}/.jbang/bin:${PATH}"; }
  jbang app install --force --fresh -Dcamel.jbang.version=4.22.0 -Dcamel-kamelets.version=4.22.0 camel@apache/camel
  grep -q '.jbang/bin' "${HOME}/.bashrc" 2>/dev/null || echo 'export PATH="${HOME}/.jbang/bin:${PATH}"' >> "${HOME}/.bashrc"
fi
camel version
