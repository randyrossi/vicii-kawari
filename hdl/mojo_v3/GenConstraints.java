import java.io.*;
import java.util.*;

public class GenConstraints
{
     public static void main(String args[]) throws Exception {
        if (args.length < 1) {
            System.out.println("Usage:");
            System.out.println("java GenConstraints wiring.txt > top.ucf");
            System.exit(0);
        }
	HashMap<String,Integer> map = new HashMap<String,Integer>();
        File f = new File(args[0]);
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
		String iostand = st.nextToken();

		System.out.println("NET \""+t6+"\" LOC="+t4+";");
                if (t7.equals("O") || t7.equals("IO")) {
                   if (!strength.equals("NA"))
		      System.out.println("NET \""+t6+"\" DRIVE="+strength+";");
                   if (!slew.equals("NA"))
		      System.out.println("NET \""+t6+"\" SLEW="+slew+";");
                   if (!iostand.equals("NA"))
		      System.out.println("NET \""+t6+"\" IOSTANDARD="+iostand+";");
                }
		if (map.get(t4) != null) { System.out.println("PIN USED TWICE " + t4); System.exit(0);}
		map.put(t4,1);
        }

	// Our clock period constraint
        System.out.println("NET \"sys_clock\" TNM_NET = clk;");
        System.out.println("TIMESPEC TS_sys_clock = PERIOD \"clk\" 50 MHz HIGH 50%;");

	// Necessary to get around routing issue.
        System.out.println("NET \"sys_clock\" CLOCK_DEDICATED_ROUTE = FALSE;");

        // Add an exception (false path) for any clk_dot4x to sys_clock crossing
        // We handle it with double FF's
        System.out.println("NET \"clk_dot4x\" TNM_NET = FFS \"GRP_1\";");
        System.out.println("NET \"sys_clock_IBUFG_BUFG\" TNM_NET = FFS \"GRP_2\";");
        System.out.println("TIMESPEC TS_except1 = FROM \"GRP_1\" TO \"GRP_2\" TIG;");
     }
}
