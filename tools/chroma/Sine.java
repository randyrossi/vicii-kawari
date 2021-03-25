import java.awt.image.BufferedImage;
import java.io.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.awt.geom.*;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.io.FileOutputStream;
import java.io.DataOutputStream; import java.util.HashMap;
import java.util.ArrayList;

// Convert grid.png to grid.bin 
public class Sine extends java.awt.Frame implements KeyListener {

    static int sine_tables[] = new int[7*256];

    public static void main(String[] args) throws Exception {
      Sine sine = new Sine(); 

      sine.setSize(640,480);
      sine.setVisible(true);

      File f = new File("sine.tables");
      FileInputStream fis = new FileInputStream(f);
      InputStreamReader ir = new InputStreamReader(fis);
      BufferedReader br = new BufferedReader(ir);

      int p=0;
      while (true) {
	      String line = br.readLine();
	      if (line == null) break;
	      int b = 256;
	      int v = 0;
	      for (int i=0;i<9;i++) {
		      if (line.charAt(i) == '1') v=v+b;
		      b=b/2;
	      }
	      
	      if (v >=256) sine_tables[p] = (-(512-v)); else sine_tables[p] = v;

	      String result = Integer.toBinaryString(sine_tables[p]+256);
 		String resultWithPadding = 
			 String.format("%9s", result).replaceAll(" ", "0");
	      System.out.println(resultWithPadding);
	      p++;
      }

      sine.repaint();
    }

    public Sine() {
        addKeyListener(this);
    }

    public void paint(Graphics g) {
       
	for (int a = 0;a<7;a++) {
	  for (int x = 0;x<256;x++) {
	    int y = sine_tables[x+256*a];
            g.drawLine(x+100,200+y,x+100,200+y);
	  }
	}
    }

    public void keyTyped(KeyEvent e) {
        //if (e.getKeyChar() == 27) edit_mode = MODE_NONE;
    }

    public void keyPressed(KeyEvent e) {
    }

    public void keyReleased(KeyEvent e) {
    }
}
