import java.io.*;
import java.util.*;

public class GenConstraints
{
  final static int HAVE_COLOR_CLOCKS = 0;
  final static int WITH_DVI = 1;
  final static int GEN_LUMA_CHROMA = 2;
  final static int HAVE_MCU_EEPROM = 3;
  final static int GEN_RGB = 4;
  final static int HAVE_EEPROM = 5;

  public static boolean[] read_config(String filename) throws Exception {
    File f = new File(filename);
    FileInputStream fis = new FileInputStream(f);
    InputStreamReader ir = new InputStreamReader(fis);
    BufferedReader br = new BufferedReader(ir);

    boolean[] flags = new boolean[6];
    while (true) {
      String line = br.readLine();
      if (line == null) break;

      if (line.startsWith("`define HAVE_COLOR_CLOCKS"))
        flags[HAVE_COLOR_CLOCKS] = true;
      else if (line.startsWith("`define WITH_DVI"))
        flags[WITH_DVI] = true;
      else if (line.startsWith("`define GEN_LUMA_CHROMA"))
        flags[GEN_LUMA_CHROMA] = true;
      else if (line.startsWith("`define HAVE_MCU_EEPROM"))
        flags[HAVE_MCU_EEPROM] = true;
      else if (line.startsWith("`define GEN_RGB"))
        flags[GEN_RGB] = true;
      else if (line.startsWith("`define HAVE_EEPROM"))
        flags[HAVE_EEPROM] = true;
    }
    return flags;
  }

  public static void main(String args[]) throws Exception {
    if (args.length < 2) {
      System.out.println("Usage:");
      System.out.println("java GenConstraints wiring.txt ../config.vh > top.ucf");
      System.exit(0);
    }

    boolean flags[] = read_config(args[1]);

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

		if (!flags[HAVE_COLOR_CLOCKS]) {
                   if (t6.equals("clk_col4x_pal")) continue;
                   if (t6.equals("clk_col4x_ntsc")) continue;
                   if (t6.startsWith("luma")) continue;
                   if (t6.startsWith("chroma")) continue;
                }
		if (!flags[GEN_LUMA_CHROMA]) {
                   if (t6.startsWith("luma")) continue;
                   if (t6.startsWith("chroma")) continue;
                }
                if (!flags[WITH_DVI]) {
                   if (t6.startsWith("TX0_TMDS")) continue;
                }

		if (!flags[HAVE_MCU_EEPROM]) {
                   if (t6.equals("chip_ext")) continue;
                   if (t6.equals("tx")) continue;
                   if (t6.equals("tx_busy")) continue;
                   if (t6.equals("rx")) continue;
                   if (t6.equals("rx_busy")) continue;
                   if (t6.equals("cclk")) continue;
                }

		if (!flags[GEN_RGB]) {
                   if (t6.startsWith("clk_dot4x_ext")) continue;
                   if (t6.startsWith("active")) continue;
                   if (t6.startsWith("vsync")) continue;
                   if (t6.startsWith("hsync")) continue;
                   if (t6.startsWith("green")) continue;
                   if (t6.startsWith("red")) continue;
                   if (t6.startsWith("blue")) continue;
                }

		if (!flags[HAVE_EEPROM]) {
                   if (t6.startsWith("eeprom_flash")) continue;
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
                if (t7.equals("I")) {
                   if (!iostand.equals("NA"))
		      System.out.println("NET \""+t6+"\" IOSTANDARD="+iostand+";");
                }
		if (map.get(t4) != null) { System.out.println("PIN USED TWICE " + t4); System.exit(0);}
		map.put(t4,1);
        }

	// Our clock period constraint
        System.out.println("NET \"sys_clock\" TNM_NET = clk;");
        System.out.println("TIMESPEC TS_sys_clock = PERIOD \"clk\" 50 MHz HIGH 50%;");

	if (flags[HAVE_COLOR_CLOCKS]) {
           System.out.println("NET \"clk_col4x_pal\" TNM_NET = color_clk_pal;");
           System.out.println("TIMESPEC TS_color_clk_pal = PERIOD \"color_clk_pal\" 17.734475 MHz HIGH 50%;");
           System.out.println("NET \"clk_col4x_ntsc\" TNM_NET = color_clk_ntsc;");
           System.out.println("TIMESPEC TS_color_clk_ntsc = PERIOD \"color_clk_ntsc\" 14.318181 MHz HIGH 50%;");
        }

        // For the prototype hat with no color clocks attached, we have to work around
        // some routing/placement issues. This seems to get things working but hopefully
        // won't be required for the final pcb since we will have color clocks. Keeping
        // this here in case color clocks don't work out for some reason.
	if (!flags[HAVE_COLOR_CLOCKS]) {
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
