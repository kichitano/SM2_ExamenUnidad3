import { Injectable, Logger } from '@nestjs/common';
import { AnswerEvaluation } from '../../../domain/entities/interview-session.entity';
import { InterviewQuestion } from '../../../domain/entities/interview-question.entity';

/**
 * AI Evaluation Service - PLACEHOLDER for future AI integration
 *
 * This service will be responsible for evaluating user answers using AI models like:
 * - OpenAI GPT-4
 * - Anthropic Claude
 * - Google Gemini
 *
 * For now, it provides mock evaluations based on answer length and keywords.
 */
@Injectable()
export class AIEvaluationService {
  private readonly logger = new Logger(AIEvaluationService.name);

  /**
   * Evaluate an answer using AI (PLACEHOLDER - currently returns mock scores)
   *
   * Future implementation will:
   * 1. Send answer to AI model with context (question, expected criteria)
   * 2. Get structured evaluation with scores for each dimension
   * 3. Get feedback and suggestions from AI
   * 4. Cache results for performance
   */
  async evaluateAnswer(
    question: InterviewQuestion,
    answerText: string,
    timeSpentSeconds?: number,
  ): Promise<AnswerEvaluation> {
    this.logger.log(`[AI PLACEHOLDER] Evaluating answer for question: ${question.id}`);

    // PLACEHOLDER: Mock evaluation based on answer length and keywords
    const answerLength = answerText.length;
    const hasMinimumLength = answerLength >= question.minimumAnswerLength;

    // Simple keyword matching (will be replaced by AI)
    const keywordMatches = this.countKeywordMatches(answerText, question.keywords || []);
    const keywordScore = Math.min(100, (keywordMatches / (question.keywords?.length || 1)) * 100);

    // Mock scores (will be replaced by AI evaluation)
    const baseScore = hasMinimumLength ? 70 : 50;
    const lengthBonus = Math.min(15, (answerLength - question.minimumAnswerLength) / 10);
    const keywordBonus = keywordScore * 0.15;

    const fluencyScore = Math.min(100, baseScore + lengthBonus);
    const grammarScore = Math.min(100, baseScore + keywordBonus);
    const vocabularyScore = Math.min(100, baseScore + keywordScore * 0.1);
    const pronunciationScore = Math.min(100, baseScore + 10); // Placeholder
    const coherenceScore = Math.min(100, baseScore + lengthBonus + keywordBonus);

    const overallQuestionScore = (
      fluencyScore * 0.25 +
      grammarScore * 0.20 +
      vocabularyScore * 0.20 +
      pronunciationScore * 0.20 +
      coherenceScore * 0.15
    );

    // Generate mock feedback
    const feedback = this.generateMockFeedback(overallQuestionScore, hasMinimumLength, keywordMatches);
    const issues = this.generateMockIssues(answerLength, keywordMatches);
    const improvements = this.generateMockImprovements(overallQuestionScore);

    const evaluation: AnswerEvaluation = {
      questionId: question.id,
      questionText: question.question,
      answerText,
      answerLength,
      submittedAt: new Date(),
      fluencyScore: Math.round(fluencyScore * 100) / 100,
      grammarScore: Math.round(grammarScore * 100) / 100,
      vocabularyScore: Math.round(vocabularyScore * 100) / 100,
      pronunciationScore: Math.round(pronunciationScore * 100) / 100,
      coherenceScore: Math.round(coherenceScore * 100) / 100,
      overallQuestionScore: Math.round(overallQuestionScore * 100) / 100,
      aiFeedback: feedback,
      detectedIssues: issues,
      suggestedImprovements: improvements,
      ...(timeSpentSeconds !== undefined && { timeSpentSeconds }),
      attemptNumber: 1,
    };

    this.logger.log(`[AI PLACEHOLDER] Evaluation complete. Overall score: ${evaluation.overallQuestionScore}`);

    return evaluation;
  }

  /**
   * Count keyword matches in answer (case-insensitive)
   */
  private countKeywordMatches(answerText: string, keywords: string[]): number {
    const lowerAnswer = answerText.toLowerCase();
    return keywords.filter(keyword => lowerAnswer.includes(keyword.toLowerCase())).length;
  }

  /**
   * Generate mock feedback based on score
   */
  private generateMockFeedback(score: number, hasMinimumLength: boolean, _keywordMatches: number): string {
    if (score >= 90) {
      return 'Excellent answer! You demonstrated strong understanding and communication skills.';
    } else if (score >= 80) {
      return 'Great job! Your answer shows good comprehension. Minor improvements could make it even better.';
    } else if (score >= 70) {
      return 'Good answer. You covered the main points, but consider adding more detail and examples.';
    } else if (score >= 60) {
      return 'Adequate response, but there\'s room for improvement in clarity and depth.';
    } else {
      return hasMinimumLength
        ? 'Your answer needs more relevant content. Focus on addressing the key aspects of the question.'
        : 'Your answer is too brief. Try to provide more detailed explanations and examples.';
    }
  }

  /**
   * Generate mock detected issues
   */
  private generateMockIssues(answerLength: number, keywordMatches: number): string[] {
    const issues: string[] = [];

    if (answerLength < 60) {
      issues.push('Answer is quite brief - consider providing more detail');
    }

    if (keywordMatches === 0) {
      issues.push('Answer may not be addressing the key concepts of the question');
    }

    // Placeholder issues (will be replaced by AI analysis)
    if (issues.length === 0) {
      return [];
    }

    return issues;
  }

  /**
   * Generate mock improvement suggestions
   */
  private generateMockImprovements(score: number): string[] {
    const improvements: string[] = [];

    if (score < 90) {
      improvements.push('Try to provide specific examples to illustrate your points');
    }

    if (score < 80) {
      improvements.push('Expand on the main concepts with more detailed explanations');
    }

    if (score < 70) {
      improvements.push('Structure your answer more clearly with introduction, body, and conclusion');
      improvements.push('Use more technical vocabulary related to the topic');
    }

    return improvements;
  }

  /**
   * FUTURE: Integration with OpenAI GPT-4
   *
   * Example implementation:
   *
   * async evaluateWithOpenAI(question: string, answer: string): Promise<Evaluation> {
   *   const prompt = `
   *     Evaluate this interview answer on a scale of 0-100 for each dimension:
   *     - Fluency
   *     - Grammar
   *     - Vocabulary
   *     - Pronunciation (based on text quality)
   *     - Coherence
   *
   *     Question: ${question}
   *     Answer: ${answer}
   *
   *     Provide feedback and suggestions in JSON format.
   *   `;
   *
   *   const response = await openai.chat.completions.create({
   *     model: 'gpt-4',
   *     messages: [{ role: 'user', content: prompt }],
   *     response_format: { type: 'json_object' },
   *   });
   *
   *   return JSON.parse(response.choices[0].message.content);
   * }
   */
}
