import com.google.protobuf.DescriptorProtos.FileDescriptorSet;
import com.google.protobuf.Descriptors;
import com.google.protobuf.DescriptorProtos;
import com.google.protobuf.DescriptorProtos.FileDescriptorProto;
import com.google.protobuf.Descriptors.FileDescriptor;
import com.google.protobuf.Descriptors.Descriptor;
import java.util.HashMap;
import java.util.Map;
import java.io.FileInputStream;

public class cberutils {


 public static void main (String ... args) {
    System.out.println(cberutils.getMapping());

 }

 public static Map<String, String> getMapping(){
     try {
         Map<String, String> mapping = new HashMap<String, String>();

         FileDescriptorSet descriptorSet = FileDescriptorSet.parseFrom(
            new FileInputStream("sensor_events.proto"));

         for (FileDescriptorProto fdp: descriptorSet.getFileList()) {
            FileDescriptor fd = FileDescriptor.buildFrom(fdp,
               new FileDescriptor[]{});

            for (Descriptor descriptor : fd.getMessageTypes()) {
              String className = fdp.getOptions().getJavaPackage() + "."
                 + fdp.getOptions().getJavaOuterClassname() + "$"
                 + descriptor.getName();
              mapping.put(descriptor.getFullName(), className);
            }
         }
         return mapping;
     }
     catch (Exception e){
        e.printStackTrace(System.out);
     }
     return null;
 }

}