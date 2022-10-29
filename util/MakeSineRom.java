import java.io.*;
import java.util.*;

public class MakeSineRom
{

  public static void main(String args[]) throws Exception {
    File f = new File("sine.bin");
    FileInputStream fis = new FileInputStream(f);
    InputStreamReader ir = new InputStreamReader(fis);
    BufferedReader br = new BufferedReader(ir);

    System.out.println("always @*");
    System.out.println("begin");
    int num = 0;
    while (true) {
      String line = br.readLine();
      if (line == null) break;

      System.out.println("    12'b"+Integer.toBinaryString(num)+": chroma9 = 9'b"+line+";");
      num++;
    }
    System.out.println("endcase");

    fis.close();
    System.out.println("end");

  }

}
