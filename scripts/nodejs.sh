
#######################
## INSTALLING NODEJS ##
#######################

installNode() {
  yum --assumeyes install curl >> $LOG

  message "Checking if node is installed"
  if node --version &>> $LOG; then
    if node --version | grep -q "v[567]"; then
      ok
      info "Already installed and version is ok"
    else
      error
      info "Node version is too old, please remove it"
    fi
    return
  else
    ok
    info "Node is currently not installed"
  fi

  message "Checking if username nodejs exists"
  if getent passwd nodejs >> $LOG 2>&1; then
    ok
    info "Username nodejs exists already"
  else
    useradd nodejs --comment "Node.js Administrator" --home-dir /usr/local/node --user-group
    chmod 755 /usr/local/node
    ok
    info "User nodejs was created"
  fi
  message "Installing node"
  mkdir -p /usr/local/node
  pushd /usr/local/node
  if [ $ARCH -eq 64 ]; then
	TAG="64"
  else
	TAG="86"
  fi
  NODE_LATEST=$(curl -s https://nodejs.org/dist/index.tab | cut -f 1 | sed -n 2p)
  curl -s https://nodejs.org/dist/${NODE_LATEST}/node-${NODE_LATEST}-linux-x${TAG}.tar.xz | tar --xz --extract
  ln -fs node-${NODE_LATEST}-linux-x${TAG} latest
  ln -fs /usr/local/node/latest/bin/node /usr/bin/node
  ln -fs /usr/local/node/latest/bin/npm /usr/bin/npm
  chown -R nodejs /usr/local/node
  ok
  message "Installing pm2"
  execnode "npm install -g pm2@latest >/dev/null 2>&1"
  popd
  if
    [ $REDHAT_RELEASE -eq 7 ]
  then
    pm2 startup systemd -u nodejs --hp /usr/local/node >> $LOG
  else
    pm2 startup centos -u nodejs --hp /usr/local/node >> $LOG
    service pm2-init.sh start >> $LOG
  fi

  pm2 kill >$LOG # for some reason there is a PM2 process running as root
  mkdir -p /usr/local/pm2
  chown nodejs /usr/local/pm2
  ok
  popd
}

installNode
