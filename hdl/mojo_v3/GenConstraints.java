import java.io.*;
import java.util.*;

public class GenConstraints
{
     public static void main(String args[]) throws Exception {
	HashMap<String,Integer> map = new HashMap<String,Integer>();
        File f = new File("wiring.txt");
        FileInputStream fis = new FileInputStream(f);
        InputStreamReader ir = new InputStreamReader(fis);
        BufferedReader br = new BufferedReader(ir);
        while (true) {
                String l = br.readLine();
                if (l == null) break;
                if (l.length() == 0 || l.startsWith("#")) continue;

		StringTokenizer st = new StringTokenizer(l," ");
		String t4 = st.nextToken();
		String t5 = st.nextToken();
		String t6 = st.nextToken();
		String t7 = st.nextToken();
		String slew = st.nextToken();
		String strength = st.nextToken();

		System.out.println("NET \""+t6+"\" LOC="+t4+";");
                if (t7.equals("O") || t7.equals("IO")) {
		   System.out.println("NET \""+t6+"\" DRIVE="+strength+";");
		   System.out.println("NET \""+t6+"\" SLEW="+slew+";");
                }
		if (map.get(t4) != null) { System.out.println("PIN USED TWICE " + t4); System.exit(0);}
		map.put(t4,1);
        }
     }
}
