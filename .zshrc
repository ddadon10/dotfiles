# Some useful aliases
alias rm="rm -i"
alias ls="ls -aF"
alias vrc="vi ~/.zshrc && source ~/.zshrc"

# Set Python3 as default
alias python="python3"
alias pip="pip3"

# Shell customization
export PS1="%n@mbp %~ %% "

# Env
export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:/opt/apache-maven-3.6.3/bin:/opt/toolbox:$PATH
