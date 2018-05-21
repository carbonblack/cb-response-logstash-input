#!/bin/bash
rm -rf lib/logstash/inputs/target
rm -rf lib/logstash/inputs/com/carbonblack
mkdir lib/logstash/inputs/target
protoc  -I lib/logstash/inputs/ --descriptor_set_out=lib/logstash/inputs/sensor_events.desc --java_out=lib/logstash/inputs/ lib/logstash/inputs/sensor_events.proto
curl -O http://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/3.3.1/protobuf-java-3.3.1.jar
cp protobuf-java-3.3.1.jar lib/logstash/inputs
cp protobuf-java-3.3.1.jar lib/logstash/inputs/target
curl -O http://repo1.maven.org/maven2/com/google/protobuf/protobuf-java-util/3.3.1/protobuf-java-util-3.3.1.jar
cp protobuf-java-util-3.3.1.jar lib/logstash/inputs
curl -OL http://search.maven.org/remotecontent?filepath=com/google/guava/guava/23.0/guava-23.0.jar
cp guava-23.0.jar lib/logstash/inputs
curl -Ok https://repo1.maven.org/maven2/com/google/code/gson/gson/2.8.1/gson-2.8.1.jar
cp gson-2.8.1.jar lib/logstash/inputs
(javac -classpath lib/logstash/inputs/protobuf-java-3.3.1.jar lib/logstash/inputs/com/carbonblack/SensorEvents/SensorEventsProtos.java -d lib/logstash/inputs/target)
(cd lib/logstash/inputs/target ; jar -cvfe SensorEvents.jar -C .)
jruby -S gem build logstash-input-cber.gemspec
jruby -S bundle update 
logstash-plugin install --no-verify logstash-input-cber-0.1.0.gem
