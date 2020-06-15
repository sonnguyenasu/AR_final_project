import java.io.FileWriter; 
import java.io.IOException; 
import java.io.FileReader;
import java.io.FileNotFoundException; 

class ManiFile
{
  private String fileName;
  ManiFile(String fName){
    this.fileName = fName;
  }
  public void writeFile(String data){
    try{
      FileWriter fw = new FileWriter(fileName);
      for(int i=0; i<data.length(); i++){
        fw.write(data.charAt(i));
      }
      println("Writing successful");
      fw.close();
    }
    catch(IOException e){
      e.printStackTrace();
    }
    
  }
  public String readFile(){
    // variable declaration 
        int ch; 
        String data = "";
        boolean ok = false;
        FileReader fr = null;
        // read from FileReader till the end of file 
        try{
          fr = new FileReader(fileName);
          ok = true;
            //System.out.print((char)ch); 
        }catch(FileNotFoundException e){
          writeFile(best_name+','+best_score);
          e.printStackTrace();
      }if(ok){
        try{
        while ((ch=fr.read())!=-1){ 
            data += (char)ch;
            println("Reading");
          }
          fr.close();
        }catch(IOException e){}
      
        println("Read successfully: ", data);
        return data;
      }else return null;
        // close the file 
        //fr.close(); 
    } 
}
