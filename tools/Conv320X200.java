import java.awt.image.BufferedImage;
import java.awt.Color;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.io.FileOutputStream;
import java.io.DataOutputStream;
import java.util.HashMap;
import java.util.TreeSet;
import java.util.ArrayList;

public class Conv320X200 {
    static boolean binaryColors = true;

    public static void main(String[] args) throws Exception {

      BufferedImage img = null;
      img = ImageIO.read(new File(args[0]));
      if (args.length > 1 && args[1].equals("-h"))
	      binaryColors = false;
      mapit(img);
    }

    static int pal[] = {
    0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x68, 0x37, 0x2b, 0x70, 0xa4, 0xb2,
    0x6f, 0x3d, 0x86, 0x58, 0x8d, 0x43, 0x35, 0x28, 0x79, 0xb8, 0xc7, 0x6f,
    0x6f, 0x4f, 0x25, 0x43, 0x39, 0x00, 0x9a, 0x67, 0x59, 0x44, 0x44, 0x44,
    0x6c, 0x6c, 0x6c, 0x9a, 0xd2, 0x84, 0x6c, 0x5e, 0xb5, 0x95, 0x95, 0x95,
    };
    static HashMap<Color,Integer> map = new HashMap<Color,Integer>();

    static int findBest(int r, int g, int b) {
       int mini = 0;
       int min = Integer.MAX_VALUE;
       for (int p=0;p<16;p++) {
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

	FileOutputStream f = new FileOutputStream(new File("320x200_0.bin"));
	FileOutputStream f2 = new FileOutputStream(new File("320x200_1.bin"));
	DataOutputStream dos = new DataOutputStream(f);
	DataOutputStream dos2 = new DataOutputStream(f2);

	int p=0;
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w++) {
              Color v = new Color(img2.getRGB(w, h));
	      Integer c = map.get(v);
              if (c == null) { c = new Integer(p); map.put(v,c); p=p+1; }
          }
        }

	if (map.keySet().size() > 16) {
		System.out.println("More than 16 colors");
		System.exit(0);
	}

	for (int z=0;z<2;z++) {
	   for (p=0;p<16;p++) {
	   for (Color col : map.keySet()) {
		if (map.get(col) == p) {
                int r = col.getRed();
                int g = col.getGreen();
                int b = col.getBlue();
                int r2 = (r >> 2);
                int g2 = (g >> 2);
                int b2 = (b >> 2);
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

	int b0=0; // byte for plane 0
	int b1=0; // byte for plane 1
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w++) {
                Color v = new Color(img2.getRGB(w, h));
		int index = map.get(v);
		//int r = v.getRed();
		//int g = v.getGreen();
		//int b = v.getBlue();
                //int index = findBest(r,g,b);

		//index = w% 16;
		//System.out.println("index = " + index);
		b0 = b0 | ((index & 0b11) << (3-w%4)*2);
		b1 = b1 | (((index >> 2) & 0b11) << (3-w%4)*2);
		//System.out.println("b0 = " + b0);
		//System.out.println("b1 = " + b1);

		if (w%4 == 3) {
                    dos.writeByte(b0); b0=0;
                    dos2.writeByte(b1); b1=0;
		}
          }
        }
	for (int i=0;i<384;i++) {
           dos.writeByte(0);
           dos2.writeByte(0);
	}
	dos.close();
	dos2.close();
    }
}
