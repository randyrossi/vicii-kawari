import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;

// Make a simple 4x5 font for numbers 0-9,a-f. Used
// for writing hex into sprites for segment1
public class Font
{
   public static void main(String args[]) throws Exception {
       FileInputStream fis = new FileInputStream("font");
       InputStreamReader ir = new InputStreamReader(fis);
       BufferedReader br = new BufferedReader(ir);
 
       int c=0;
       while (true) {
           String line = br.readLine();
           if (line == null) break;
           int b = 8;
           int nb = 0;
           for (int t=0;t<4;t++) {
              if (line.charAt(t) == 'X')
                  nb=nb+b;
              b=b/2;
           }
           System.out.print(nb);
           if (c < 4) System.out.print(",");
           c=c+1;
           if (c == 5) { System.out.println(); c = 0; }
       }
   }
}
