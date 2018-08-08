// app/views/exports/export_glossaries.js.haml
:plain
  var interval;
  $('.export .well').show();
  interval = setInterval(function(){
    $.ajax({
      url: '/progress-job/' + #{@job.id},
      success: function(job){
        var stage, progress;

        // If there are errors
        if (job.last_error != null) {
          $('.progress-status').addClass('text-danger').text(job.progress_stage);
          $('.progress-bar').addClass('progress-bar-danger');
          $('.progress').removeClass('active');
          clearInterval(interval);
        }

        progress = job.progress_current / job.progress_max * 100;
        // In job stage
        if (progress.toString() !== 'NaN'){
          $('.progress-status').text(job.progress_current + '/' + job.progress_max);
          $('.progress-bar').css('width', progress + '%').text(progress + '%');
        }
      },
      error: function(){
        // Job is no loger in database which means it finished successfuly
        $('.progress').removeClass('active');
        $('.progress-bar').css('width', '100%').text('100%');
        $('.progress-status').text('Successfully exported!');
        $('.export-link').show();
        clearInterval(interval);
      }
    })
  },100);