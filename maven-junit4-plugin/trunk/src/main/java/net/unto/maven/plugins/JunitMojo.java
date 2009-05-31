package net.unto.maven.plugins;

import java.io.File;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.junit.runner.Description;
import org.junit.runner.notification.Failure;

/**
 * @goal test
 * @description Runs all unit test classes
 */
public class JunitMojo extends AbstractMojo
{
  private static final File CLASSES_DIRECTORY = new File( "target/classes/" );

  private static final File TEST_CLASSES_DIRECTORY = new File( "target/test-classes/" );

  private static final File[ ] TEST_CLASSPATH = { CLASSES_DIRECTORY, TEST_CLASSES_DIRECTORY };

  /* When run, this mojo will recurse through the target/test-classes directory
   * and run all JUnit 4 tests. 
   *
   * @see org.apache.maven.plugin.AbstractMojo#execute()
   */
  public void execute( ) throws MojoExecutionException
  {
    JunitRunner runner = new JunitRunner( TEST_CLASSPATH );
    ResultAccumulator resultAccumulator = runner.runAllTests( TEST_CLASSES_DIRECTORY );
    String report = buildReport( resultAccumulator );
    getLog( ).info( report );
  }

  private String buildReport( ResultAccumulator resultAccumulator )
  {
    StringBuffer report = new StringBuffer( );
    appendReportHeader( report, resultAccumulator );

    for ( Failure failure : resultAccumulator.getFailures( ) )
    {
      appendFailure( report, failure );
    }

    return report.toString( );
  }

  private void appendReportHeader( StringBuffer report, ResultAccumulator resultAccumulator )
  {
    assert ( report != null );
    report.append( "\n" );
    report.append( "-------------------------------------------------------\n" );
    report.append( "  T E S T S\n" );
    report.append( "-------------------------------------------------------\n" );
    report.append( "\n" );
    report.append( "Results:\n" );
    report.append( "[junit] Tests run: " + resultAccumulator.getRunCount( ) + ", Failures: " + resultAccumulator.getFailureCount( )
        + "\n" );
    report.append( "\n" );
  }

  private void appendFailure( StringBuffer report, Failure failure )
  {
    report.append( "Test " + failure.getTestHeader( ) + " failed:\n" );
    appendDescription( report, failure.getDescription( ) );
    report.append( "  Exception: " + failure.getException( ).toString( ) + "\n" );
    report.append( "  " + failure.getTrace( ) + "\n" );
  }

  private void appendDescription( StringBuffer report, Description description )
  {
    assert ( description != null );
    report.append( "  Description " + description.getDisplayName( ) + " failed\n" );
    report.append( "    " + description.toString( ) + "\n" );

    for ( Description child : description.getChildren( ) )
    {
      appendDescription( report, child );
    }
  }
}
