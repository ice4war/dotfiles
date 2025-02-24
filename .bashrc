# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

# Path to your oh-my-bash installation.
export OSH='/home/subzero/.oh-my-bash'

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
OSH_THEME="font"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"
OMB_USE_SUDO=true

source "$OSH"/oh-my-bash.sh
unset HISTTIMEFORMAT
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=200000

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

eval "$(starship init bash)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/opt/miniconda/etc/profile.d/conda.sh" ]; then
    . "/opt/miniconda/etc/profile.d/conda.sh"
  else
    export PATH="/opt/miniconda/bin:$PATH"
  fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=$PATH:$HOME/.local/bin
export PATH="$HOME/go/bin:$PATH"
#export CLASSPATH="/opt/apache/jars/*:$CLASSPATH"
#export CLASSPATH="/opt/apache/jars/java:$CLASSPATH"
#export CLASSPATH="~/.cache/coursier/v1/https/repo1.maven.org/maven2/*/*/*/*/*/*/*.jar:$CLASSPATH"
#export CLASSPATH="~/.cache/coursier/v1/https/repo1.maven.org/maven2/*/*/*/*/*/*.jar:$CLASSPATH"
#export CLASSPATH="~/.cache/coursier/v1/https/repo1.maven.org/maven2/*/*/*/*/*.jar:$CLASSPATH"
#export CLASSPATH="~/.cache/coursier/v1/https/repo1.maven.org/maven2/*/*/*/*.jar:$CLASSPATH"

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

#export HADOOP_HOME=/usr/local/share/hadoop
#export HADOOP_INSTALL=$HADOOP_HOME
#export HADOOP_MAPRED_HOME=$HADOOP_HOME
#export HADOOP_COMMON_HOME=$HADOOP_HOME
#export HADOOP_HDFS_HOME=$HADOOP_HOME
#export YARN_HOME=$HADOOP_HOME
#export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
#export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
#export LD_LIBRARY_PATH="$HADOOP_COMMON_LIB_NATIVE_DIR:$LD_LIBRARY_PATH"
#export PATH=$PATH:$HADOOP_HOME/bin

#export SPARK_HOME=/usr/local/share/spark
#export PATH=$SPARK_HOME/bin:$PATH

#export HIVE_HOME=/usr/local/share/hive
#export PATH=$HIVE_HOME/bin:$PATH

#export ZEPPELIN_HOME=/opt/apache/zeppelin
#export PATH=$ZEPPELIN_HOME/bin:$PATH

#export KAFKA_HOME=/usr/local/share/kafka
#export PATH=$KAFKA_HOME/bin:$PATH
#export KAFKA_HEAP_OPTS="-Xmx512M -Xms512M"

#export ZOOKEEPER_HOME=/usr/local/share/zookeeper
#export PATH=$ZOOKEEPER_HOME/bin:$PATH

#export CASSANDRA_HOME=/usr/local/share/cassandra
#export PATH=$CASSANDRA_HOME/bin:$PATH


export PATH="$PATH:$HOME/.rbenv/bin"
