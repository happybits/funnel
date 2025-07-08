Ok lets add a new feature. The current transcript card shows a raw transcript, but lets make it lightly edited for clarity. So we'll need server code to 
  convert raw transcript to lightly edited one. This should be returned when we return the other cards like bulleted summary. Please go figure out which 
  endpoint that is. It might be two since there's endpoint for uploading whole file and endpoint for streaming an audio file i think. 
  Anyways so then we should display the lightly edited transcript on the client rather than raw one. Lets make sure the client's models etc. call it 
  lightly_edited_transcript for clarity. Also please make sure all the tests pass first, then make sure to update them as needed so they still pass after 
  making your changes
