package net.unto.maven.plugins;

import org.junit.runner.Result;
import org.junit.runner.notification.Failure;
import java.util.List;
import java.util.ArrayList;

public class ResultAccumulator
{
  private int _failureCount = 0;
  private int _ignoreCount = 0;
  private int _runCount = 0;
  private long _runTime = 0;
  private boolean _wasSuccessful = true;
  private List<Failure> _failures = new ArrayList<Failure>( );

  protected void addResult( Result result )
  {
    assert( result != null );
    _failureCount += result.getFailureCount( );
    _ignoreCount += result.getIgnoreCount( );
    _runCount += result.getRunCount( );
    _runTime += result.getRunTime( );
    _failures.addAll( result.getFailures( ) );
    if ( !result.wasSuccessful( ) )
    {
      _wasSuccessful = false;
    }
  }

  public int getFailureCount( )
  {
    return _failureCount;
  }

  public int getIgnoreCount( )
  {
    return _ignoreCount;
  }

  public int getRunCount( )
  {
    return _runCount;
  }

  public long getRunTime( )
  {
    return _runTime;
  }

  public List<Failure> getFailures( )
  {
    return _failures;
  }

  public boolean wasSuccessful( )
  {
    return _wasSuccessful;
  }
}
