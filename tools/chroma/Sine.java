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

      if (args.length == 0) {
         sine.setSize(640,600);
	 sine.setVisible(true);
      }

      int num_waves = 7;
      double max_amp = 230;
      double min_amp = 60;

      double amp = max_amp;
      double amp_step = (max_amp - min_amp) / (num_waves-1);
      int p = 0;
      for (int wave = 0; wave < num_waves; wave++) {
         for (int x = 0; x < 256; x++) {
            int y = (int)(Math.sin(x/40.74366) * amp); // 256/(2*pi)
	    sine_tables[p++] = y;
	    String binary = Integer.toBinaryString(y);
	    while (binary.length() < 9) binary = "0" + binary;
	    System.out.println(binary.substring(binary.length()-9,binary.length()));
	 }
	 amp=amp-amp_step;
      }

      if (args.length == 0) {
         sine.repaint();
      }
    }

    public Sine() {
        addKeyListener(this);
    }

    public void paint(Graphics g) {
        int left = 100;
        int cy = 300;	
        g.drawLine(left,cy+256,left,cy-256);
        g.drawLine(left,cy+256,left+256,cy+256);
	for (int a = 0;a<7;a++) {
	  for (int x = 0;x<256;x++) {
	    int y = sine_tables[x+256*a];
            g.drawLine(x+left,cy+y,x+left,cy+y);
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
