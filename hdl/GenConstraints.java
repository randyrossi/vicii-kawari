import java.io.*;
import java.util.*;

public class GenConstraints
{
  final static int WITH_DVI = 0;
  final static int GEN_LUMA_CHROMA = 1;
  final static int GEN_RGB = 2;
  final static int HAVE_EEPROM = 3;
  final static int HAVE_FLASH = 4;
  final static int WITH_EXTENSIONS = 5;
  final static int WITH_CLOCK_MUX = 6;

  public static boolean[] read_config() throws Exception {


    File f = new File("config.vh");
    FileInputStream fis = new FileInputStream(f);
    InputStreamReader ir = new InputStreamReader(fis);
    BufferedReader br = new BufferedReader(ir);

    boolean[] flags = new boolean[7];

    // Assume we have a clock mux
    flags[WITH_CLOCK_MUX] = true;

    while (true) {
      String line = br.readLine();
      if (line == null) break;

      if (line.startsWith("`define WITH_DVI"))
        flags[WITH_DVI] = true;
      else if (line.startsWith("`define GEN_LUMA_CHROMA"))
        flags[GEN_LUMA_CHROMA] = true;
      else if (line.startsWith("`define GEN_RGB"))
        flags[GEN_RGB] = true;
      else if (line.startsWith("`define HAVE_EEPROM"))
        flags[HAVE_EEPROM] = true;
      else if (line.startsWith("`define HAVE_FLASH"))
        flags[HAVE_FLASH] = true;
      else if (line.startsWith("`define WITH_EXTENSIONS"))
        flags[WITH_EXTENSIONS] = true;
      if (line.startsWith("`define NO_CLOCK_MUX"))
        flags[WITH_CLOCK_MUX] = false;
    }

    fis.close();

    return flags;
  }

  public static void main(String args[]) throws Exception {
    if (args.length < 1) {
      System.out.println("Usage:");
      System.out.println("java GenConstraints wiring.txt > top.ucf");
      System.exit(0);
    }

    boolean flags[] = read_config();

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

		if (!flags[GEN_LUMA_CHROMA]) {
                   if (t6.startsWith("luma")) continue;
                   if (t6.startsWith("chroma")) continue;
                }
                if (!flags[WITH_DVI]) {
                   if (t6.startsWith("TX0_TMDS")) continue;
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
                   if (t6.startsWith("cfg_reset")) continue;
                   if (t6.startsWith("eeprom_s")) continue;
                }
		if (!flags[HAVE_FLASH]) {
                   if (t6.startsWith("flash_s")) continue;
                }
		if (!flags[HAVE_EEPROM] && !flags[HAVE_FLASH]) {
                   if (t6.startsWith("spi_d")) continue;
                   if (t6.startsWith("spi_q")) continue;
                   if (t6.startsWith("spi_c")) continue;
                   if (t6.startsWith("flash_d1")) continue;
                   if (t6.startsWith("flash_d2")) continue;
                }
		if (!flags[WITH_EXTENSIONS]) {
                   if (t6.startsWith("cfg1")) continue;
                   if (t6.startsWith("cfg2")) continue;
                   if (t6.startsWith("cfg3")) continue;
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
                   if (slew.equals("PULLUP") || slew.equals("PULLDOWN"))
		      System.out.println("NET \""+t6+"\" "+slew+";");
                   if (!iostand.equals("NA"))
		      System.out.println("NET \""+t6+"\" IOSTANDARD="+iostand+";");
                }
		if (map.get(t4) != null) { System.out.println("PIN USED TWICE " + t4); System.exit(0);}
		map.put(t4,1);
        }

	if (flags[WITH_CLOCK_MUX]) {
           System.out.println("NET \"clk_col4x_pal\" TNM_NET = color_clk_pal;");
           System.out.println("TIMESPEC TS_color_clk_pal = PERIOD \"color_clk_pal\" 17.734475 MHz HIGH 50%;");
           System.out.println("NET \"clk_col4x_ntsc\" TNM_NET = color_clk_ntsc;");
           System.out.println("TIMESPEC TS_color_clk_ntsc = PERIOD \"color_clk_ntsc\" 14.318181 MHz HIGH 50%;");
	} else {
           System.out.println("NET \"clk_col4x_either\" TNM_NET = color_clk_either;");
           System.out.println("TIMESPEC TS_color_clk_either = PERIOD \"color_clk_either\" 17.734475 MHz HIGH 50%;");
	}
     }
}
