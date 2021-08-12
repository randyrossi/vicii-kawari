import java.awt.image.BufferedImage;
import java.awt.Color;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.io.FileOutputStream;
import java.io.DataOutputStream;
import java.util.HashMap;
import java.util.TreeMap;
import java.util.ArrayList;

// Convert grid.png to grid.bin 
public class Conv640X200 {
    static boolean binaryColors = true;

    public static void main(String[] args) throws Exception {

      BufferedImage img = null;
      img = ImageIO.read(new File(args[0]));
      if (args.length > 1 && args[1].equals("-h"))
              binaryColors = false;

      mapit(img);
    }

    static int pal[] = {
    0, 0, 0, 63, 63, 63, 127, 127, 127, 255, 255, 255,
    };

    static HashMap<Color,Integer> map = new HashMap<Color,Integer>();


    static int findBest(int r, int g, int b) {
       int mini = 0;
       int min = Integer.MAX_VALUE;
       for (int p=0;p<4;p++) {
	       int r2 = pal[p*3];
	       int g2 = pal[p*3+1];
	       int b2 = pal[p*3+2];
	       int dist = (int)(Math.sqrt((r-r2)*(r-r2)+
	                  (g-g2)*(g-g2)+
	                  (b-b2)*(b-b2)));
	       if (dist < min) {
		       min = dist;
		       mini = p;
	       }
       }
       return mini;
    }

    public static void mapit(BufferedImage img2) throws Exception {

        int height = img2.getHeight();
        int width = img2.getWidth();

	FileOutputStream f = new FileOutputStream(new File("640x200.bin"));
	DataOutputStream dos = new DataOutputStream(f);

	int p=0;
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w++) {
              Color v = new Color(img2.getRGB(w, h));
              Integer c = map.get(v);
              if (c == null) { c = new Integer(p); map.put(v,c); p=p+1; }
          }
        }

        if (map.keySet().size() > 4) {
                System.out.println("More than 4 colors");
                System.exit(0);
        }

        for (int z=0;z<4;z++) {
           for (p=0;p<4;p++) {
           for (Color col : map.keySet()) {
                if (map.get(col) == p) {
                int r = col.getRed();
                int g = col.getGreen();
                int b = col.getBlue();
                int r2 = (r >> 2);
                int g2 = (g >> 2);
                int b2 = (b >> 2);
                // Populate the upper color banks with RGB shades
                // for testing the color_base for 4 col hires mode
                if (z==1) {r2=0; g2=0;};
                if (z==2) {b2=0; g2=0;};
                if (z==3) {b2=0; r2=0;};
                int v = (r2 << 12) | (g2 << 6) | b2;

		if (binaryColors) {
                   String s = Integer.toBinaryString(v);
                   while (s.length() < 18) s="0"+s;
                   System.out.println(s+"000000");
                } else {
                   String s1 = Integer.toHexString(r2);
                   if (s1.length() < 2) s1="0"+s1;
                   String s2 = Integer.toHexString(g2);
                   if (s2.length() < 2) s2="0"+s2;
                   String s3 = Integer.toHexString(b2);
                   if (s3.length() < 2) s3="0"+s3;
                   System.out.println(s1+" "+s2+" "+s3+" 00");
                }
              }
            }
          }
        }

	int b1=0;
	int b2=0;
	int b3=0;
	int b4=0;
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w=w+4) {
                Color v = new Color(img2.getRGB(w, h));
                int index = map.get(v);
                b1 = index & 0b11;
                v = new Color(img2.getRGB(w+1, h));
                index = map.get(v);
                b2 = index & 0b11;
                v = new Color(img2.getRGB(w+2, h));
                index = map.get(v);
                b3 = index & 0b11;
                v = new Color(img2.getRGB(w+3, h));
                index = map.get(v);
                b4 = index & 0b11;

                dos.writeByte(b1 << 6 | b2 << 4 | b3 << 2 | b4);
          }
        }
	for (int i=0;i<384*2;i++) {
           dos.writeByte(0);
	}
	dos.close();
    }
}
