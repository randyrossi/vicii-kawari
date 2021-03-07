import java.io.*;
import java.util.*;

public class GenConstraints
{
     public static void main(String args[]) throws Exception {
        if (args.length < 2) {
            System.out.println("Usage:");
            System.out.println("java GenConstraints wiring.txt have_color_clocks > top.ucf");
            System.exit(0);
        }
	// The prototype 'hat' for the mojov3 was originally designed with no
	// ntsc/pal color clocks going into the board.  In this case, we rely soley
	// on the on-board 50mhz clock to generate our pixel clocks for both ntsc
	// and pal.  This caused some routing and placement issues and hopefully
	// won't be necessary on the final pcb since we have figured out how to
	// properly generate dot4x clocks from color clocks.  For 'plain' unmodified
	// boards to still work, pass in 'false' or 'no' for this cmd line flag and
	// the 'legacy' top.uc will be generated. (i.e. the one that Adrian Black
	// has.)
        boolean have_color_clocks = args[1].equals("yes") || args[1].equals("true");
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

		if (!have_color_clocks) {
                   if (t6.equals("clk_col4x_pal")) continue;
                   if (t6.equals("clk_col4x_ntsc")) continue;
                   if (t6.equals("clk_colref")) continue;
                   if (t6.equals("csync")) continue;
                   if (t6.equals("is_composite")) continue;
                }

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

	if (have_color_clocks) {
           System.out.println("NET \"clk_col4x_pal\" TNM_NET = color_clk_pal;");
           System.out.println("TIMESPEC TS_color_clk_pal = PERIOD \"color_clk_pal\" 17.734475 MHz HIGH 50%;");
           System.out.println("NET \"clk_col4x_ntsc\" TNM_NET = color_clk_ntsc;");
           System.out.println("TIMESPEC TS_color_clk_ntsc = PERIOD \"color_clk_ntsc\" 14.318181 MHz HIGH 50%;");
        }

        // For the prototype hat with no color clocks attached, we have to work around
        // some routing/placement issues. This seems to get things working but hopefully
        // won't be required for the final pcb since we will have color clocks. Keeping
        // this here in case color clocks don't work out for some reason.
	if (!have_color_clocks) {
	  // Necessary to get around routing issue.
          System.out.println("NET \"sys_clock\" CLOCK_DEDICATED_ROUTE = FALSE;");

          // Add an exception (false path) for any clk_dot4x to sys_clock crossing
          // We handle it with double FF's
          System.out.println("NET \"clk_dot4x\" TNM_NET = FFS \"GRP_1\";");
          System.out.println("NET \"sys_clock_IBUFG_BUFG\" TNM_NET = FFS \"GRP_2\";");
          System.out.println("TIMESPEC TS_except1 = FROM \"GRP_1\" TO \"GRP_2\" TIG;");
       }
     }
}
