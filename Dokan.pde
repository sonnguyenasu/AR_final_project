
class Dokan {

    private float dxIndiv;
    private float dyIndiv;
    private float pipeWidth;
    private float pipeGap;
    private float pipeInterval;

    Dokan(float pipeWidth, float pipeGap, float pipeInterval) {
        this.pipeWidth = pipeWidth;
        this.pipeGap = pipeGap;
        this.pipeInterval = pipeInterval;
    }

    void setX(float x) {
        dxIndiv = x;
    }

    void setY(float y) {
        dyIndiv = y;
    }

    float getX() {
        return dxIndiv;
    }

    float getY() {
        return dyIndiv;
    }

    void draw(int score, int width, int height) {
        // draw pipe
        dxIndiv = dxIndiv - 5;
        //float pipeWidth = 50;
        //float pipeGap = random(75,150);
        if (dxIndiv + pipeWidth < 0) {
            dxIndiv = width;
            dyIndiv = random(height/2, width/2);
            score = score + 1;
            pipeGap = pipeGap-1;
        }
        //lower pipe
        //fill(0, 255, 0);
        //rect(dx, dy, 50, height - dy);
        drawThePipe(dxIndiv, dyIndiv, height-dyIndiv);
        // upper pipe
        //fill(0,255,0);
        //rect(dx, 0, 50, dy - 150);
        drawThePipe(dxIndiv, 0, dyIndiv-pipeGap);
    }

    //draw the pipe with gradient color
    void drawThePipe(float px, float py, float pipeHeight){
        for(float i = px; i < px+pipeWidth; i++){
            //idx variable to set up the color
            int idx = (int)((i - px)*256/pipeWidth);
            stroke(0,255-idx,255-idx>>1);
            line(i,py,i,py+pipeHeight);
        }
    }
}