package net.unto.maven.plugins;

import java.io.File;
import java.io.FileFilter;
import java.io.IOException;

/**
 * Filter out everything but .class files and directories.
 * 
 * @author dewitt
 */
public class ClassFileFilter implements FileFilter
{  
  /* Return false for everything except directories (to allow it to recurse) and .class files.
   * 
   * @see java.io.FileFilter#accept(java.io.File)
   */
  public boolean accept( File file )
  {
    try
    {
      return ( file.isDirectory( ) || file.getCanonicalPath( ).endsWith( ".class" ) );
    }
    catch ( IOException e )
    {
      throw new RuntimeException( e );
    }
  }
}

