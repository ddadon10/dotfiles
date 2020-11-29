# Some useful aliases
alias rm="rm -i"
alias ls="ls -aF"
alias vrc="vi ~/.zshrc && source ~/.zshrc"

# Put Python3 as default
alias python="python3"
alias pip="pip3"

# Env
export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:/opt/apache-maven-3.6.3/bin:/opt/toolbox:$PATH
PS1="%n@mbp %~ %% "
