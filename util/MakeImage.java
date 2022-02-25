import java.awt.image.BufferedImage;
import java.awt.Color;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.io.FileOutputStream;
import java.io.DataOutputStream;
import java.io.BufferedOutputStream;
import java.util.HashMap;
import java.util.TreeSet;
import java.util.ArrayList;

public class MakeImage {
    enum ColorFormat {
        BIN,
        BINARY,
        HEX,
    }

    static ColorFormat colorFormat = ColorFormat.BINARY;

    enum Mode {
        MODE_320x200x16,
        MODE_640x200x4
    };

    static Mode mode;
    static int maxColors;
    static String imageBinFileName;
    static String colorBinFileName;

    public static void main(String[] args) throws Exception {

      BufferedImage img = null;
      if (args.length < 4) {
          System.out.println(
              "java MakeImage [options] <mode> <image.png> <output.bin> <colors.bin>");
          System.out.println("where");
          System.out.println("    options");
          System.out.println("        -bin");
          System.out.println("        -binary");
          System.out.println("        -hex");
          System.out.println("    mode = 320x200x16 or 640x200x4");
          System.exit(0);
      }

      int argIdx = 0;

      while (args[argIdx].startsWith("-")) {
         if (args[argIdx].equals("-bin")) 
            colorFormat = ColorFormat.BIN;
         else if (args[argIdx].equals("-binary"))
            colorFormat = ColorFormat.BINARY;
         else if (args[argIdx].equals("-hex"))
            colorFormat = ColorFormat.HEX;
         argIdx++;
      }

      String modeString = args[argIdx++];
      if (modeString.equals("320x200x16")) {
          mode = Mode.MODE_320x200x16;
      } else if (modeString.equals("640x200x4")) {
          mode = Mode.MODE_640x200x4;
      } else {
          System.out.println("Unrecognized mode " + modeString);
          System.exit(0);
      }

      maxColors = mode == Mode.MODE_320x200x16 ? 16 : 4;
     
      img = ImageIO.read(new File(args[argIdx++])); 
      imageBinFileName = args[argIdx++];
      colorBinFileName = args[argIdx++];

      mapit(img);
    }

    static HashMap<Color,Integer> map = new HashMap<Color,Integer>();

    public static void mapit(BufferedImage img2) throws Exception {

        int height = img2.getHeight();
        int width = img2.getWidth();

        if (mode == Mode.MODE_320x200x16 && (width != 320 || height !=200)) {
            System.out.println("Image is not 320x200");
            System.exit(0);
        } else if (mode == Mode.MODE_640x200x4 &&
               (width != 640 || height !=200)) {
            System.out.println("Image is not 640x200");
            System.exit(0);
        }

	FileOutputStream f = new FileOutputStream(new File(imageBinFileName));
	DataOutputStream dos = new DataOutputStream(f);

	FileOutputStream f2 = new FileOutputStream(new File(colorBinFileName));
	BufferedOutputStream bos = new BufferedOutputStream(f2);

	int p=0;
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w++) {
              Color v = new Color(img2.getRGB(w, h));
	      Integer c = map.get(v);
              if (c == null) { c = new Integer(p); map.put(v,c); p=p+1; }
          }
        }

	if (map.keySet().size() > maxColors) {
           System.out.println("More than " + maxColors +" colors");
           System.exit(0);
	}

        // Make color file
	for (p=0;p<maxColors;p++) {
	   for (Color col : map.keySet()) {
		if (map.get(col) == p) {
                   int r = col.getRed();
                   int g = col.getGreen();
                   int b = col.getBlue();
                   int r2 = (r >> 2);
                   int g2 = (g >> 2);
                   int b2 = (b >> 2);
                   int v = (r2 << 12) | (g2 << 6) | b2;

		   if (colorFormat == ColorFormat.BINARY) {
                      String s = Integer.toBinaryString(v);
                      while (s.length() < 18) s="0"+s;
                      String l = s+"000000\n";
                      bos.write(l.getBytes());
		   } else if (colorFormat == ColorFormat.HEX) {
                      String s1 = Integer.toHexString(r2);
		      if (s1.length() < 2) s1="0"+s1;
                      String s2 = Integer.toHexString(g2);
		      if (s2.length() < 2) s2="0"+s2;
                      String s3 = Integer.toHexString(b2);
		      if (s3.length() < 2) s3="0"+s3;
                      String l = s1+" "+s2+" "+s3+" 00\n";
                      bos.write(l.getBytes());
		   } else {
                      bos.write((byte)r2);
                      bos.write((byte)g2);
                      bos.write((byte)b2);
                      bos.write((byte)0);
                   }
                }
	    }
	}

        // Make image binary file

        if (mode == Mode.MODE_320x200x16) {
	  int nhi=0; // upper nibble
	  int nlo=0; // lower nibble
          for (int h=0;h< height;h++) {
            for (int w=0;w< width;w=w+2) {
                Color v = new Color(img2.getRGB(w, h));
		int index = map.get(v);
                nhi = index & 0b1111;
                v = new Color(img2.getRGB(w+1, h));
		index = map.get(v);
                nlo = index & 0b1111;
                
                dos.writeByte(nhi << 4 | nlo);
            }
          }
        } else {
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
        }

	for (int i=0;i<384*2;i++) {
           dos.writeByte(0);
	}
	dos.close();
	bos.close();
    }
}
