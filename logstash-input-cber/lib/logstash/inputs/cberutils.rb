require 'java'
require "./protobuf-java-3.3.1.jar"
$CLASSPATH<<File.join(Dir.pwd, ".")
java_import com.google.protobuf.DescriptorProtos
java_import com.google.protobuf.Descriptors

java_import java.io.FileInputStream

require './protobuf-java-3.3.1.jar'
require './target/SensorEvents.jar'
require './protobuf-java-util-3.3.1.jar'
require './gson-2.8.1.jar'
require './guava-23.0.jar'
java_import "com.carbonblack.SensorEvents.SensorEventsProtos"
java_import "com.google.protobuf.util.JsonFormat"


 mapping = {}

 inputstream = java.io.FileInputStream.new("lib/logstash/inputs/sensor_events.desc")

 descriptorSet = com.google.protobuf.Descriptors.FileDescriptorSet.parseFrom(inputstream)


 for  fdp in descriptorSet.getFileList() do
    fd = FileDescriptor.buildFrom(fdp,FileDescriptor[0].new)

    for descriptor in fd.getMessageTypes() do
      className = fdp.getOptions().getJavaPackage() + "."
         + fdp.getOptions().getJavaOuterClassname() + "$"
         + descriptor.getName()
      mapping[descriptor.getFullName()] = className
    end
 end