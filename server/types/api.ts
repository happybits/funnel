export interface NewRecordingResponse {
  transcript: string;
  lightlyEditedTranscript: string;
  duration: number;
  bulletSummary: string[];
  diagram: {
    title: string;
    description: string;
    content: string;
  };
  thoughtProvokingQuestions: string[];
}

export interface ErrorResponse {
  error: string;
  details?: string;
}
