echo "Creating /home/vcap/.grails-static-website"
mkdir /home/vcap/.grails-static-website

$JAVA_HOME/bin/java -XshowSettings:all -XX:+PrintFlagsFinal $JAVA_OPTS -version > /home/vcap/logs/java_flags.log 2> /home/vcap/logs/java_info.log
env > /home/vcap/logs/env.log
ulimit -a > /home/vcap/logs/ulimit.log
