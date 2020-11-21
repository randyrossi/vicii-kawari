import java.io.*;
import java.util.*;

public class MakeReport
{
     public static void main(String args[]) throws Exception {
        File f = new File("list.txt");
        FileInputStream fis = new FileInputStream(f);
        InputStreamReader ir = new InputStreamReader(fis);
        BufferedReader br = new BufferedReader(ir);
	System.out.println("<body>");
	System.out.println("<table>");
        while (true) {
                String l = br.readLine();
                if (l == null) break;
                if (l.length() == 0) continue;
		int i = l.lastIndexOf("/");
		String d = l.substring(0,i);
		String fn = l.substring(i+1);

		System.out.println("<tr>");
		System.out.println("<td>");
		System.out.println(l);
		System.out.println("</td>");
		System.out.println("</tr>");

		System.out.println("<tr>");
		System.out.println("<td>");
		System.out.println("<img src=\""+d+"/vice_"+fn+".png\"></img>");
		System.out.println("</td>");
		System.out.println("<td>");
		System.out.println("<img src=\""+d+"/fpga_"+fn+".png\"></img>");
		System.out.println("</td>");
		System.out.println("<td>");
		System.out.println("<textarea rows=\"10\" cols=\"50\">");

        File f2 = new File(d+"/vice_"+fn+".log");
	if (f2.exists()) {
           FileInputStream fis2 = new FileInputStream(f2);
           InputStreamReader ir2 = new InputStreamReader(fis2);
           BufferedReader br2 = new BufferedReader(ir2);
	   int count=0;
	   while (count < 10) {
                String l2 = br2.readLine();
                if (l2 == null) break;
		System.out.println(l2);
		count++;
	   }
	} else {
		System.out.println("DID NOT RUN");
        }

		System.out.println("</textarea>");
		System.out.println("</td>");
		System.out.println("</tr>");
        }
	System.out.println("</table>");
	System.out.println("</body>");
     }
}
