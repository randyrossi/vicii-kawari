import java.io.*;
import java.util.*;

// Simple pre-parser to handle goto and gosub labels
// Lables must be prefixed with l_
public class BasicGen
{
     public static void main(String args[]) throws Exception {
	// Remember labels to line numbers
	HashMap<String,Integer> map = new HashMap<String,Integer>();
        File f = new File(args[0]);
        FileInputStream fis = new FileInputStream(f);
        InputStreamReader ir = new InputStreamReader(fis);
        BufferedReader br = new BufferedReader(ir);
	int ln = 10;
        while (true) {
                String l = br.readLine();
                if (l == null) break;
                if (l.indexOf("rem l_") >=0) {
		   StringTokenizer st = new StringTokenizer(l," ");
		   String rem = st.nextToken();
		   String label = st.nextToken();
		   map.put(label, ln);
		}
                if (l.length() == 0) continue;
                if (l.startsWith("#")) continue;
		ln+=10;
        }

	// Open again
        fis = new FileInputStream(f);
        ir = new InputStreamReader(fis);
        br = new BufferedReader(ir);
	ln = 10;
        while (true) {
                String l = br.readLine();
                if (l == null) break;
		for (String lab: map.keySet()) {
			l=l.replaceAll(lab,""+map.get(lab));
		}
                if (l.length() == 0) continue;
                if (l.startsWith("#")) continue;
		System.out.println(ln + " " + l); ln+=10;
        }

     }
}
