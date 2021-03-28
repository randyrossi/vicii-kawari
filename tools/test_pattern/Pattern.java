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

public class Pattern {
    public static void main(String[] args) throws Exception {

      BufferedImage img = null;
      img = ImageIO.read(new File(args[0]));
      mapit(img);
    }

    static int pal[] = {
    0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xbb, 0x61, 0x51, 0xa9, 0xf3, 0xff,
    0xcd, 0x6f, 0xd4, 0x89, 0xe5, 0x81, 0x69, 0x53, 0xf5, 0xed, 0xed, 0x72,
    0xc6, 0x92, 0x32, 0x8d, 0x79, 0x00, 0xf5, 0xab, 0x96, 0x81, 0x81, 0x81,
    0xb3, 0xb3, 0xb3, 0xcd, 0xff, 0xc6, 0xb1, 0xef, 0xff, 0xb1, 0x9e, 0xff,
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

	int l=0;
        for (int h=0;h< height;h++) {
          for (int w=0;w< width;w++) {
                Color v = new Color(img2.getRGB(w, h));
		int r = v.getRed();
		int g = v.getGreen();
		int b = v.getBlue();
                int index = findBest(r,g,b);

		String bi = Integer.toBinaryString(index);
		while (bi.length() < 4) bi= "0"+bi;
		System.out.println(bi);
          }
        }
	for (int pad=0; pad<16384-(height*width);pad++) 
		System.out.println("0110");
    }
}
