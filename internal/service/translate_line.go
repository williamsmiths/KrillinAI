package service

import (
	"context"
	"fmt"
	"krillin-ai/internal/types"
	"strings"
)

func (s Service) TranslateDialogueLine(
	ctx context.Context,
	previousSentences string,
	targetSentence string,
	nextSentences string,
	targetLang types.StandardLanguageCode,
) (string, string, error) {
	_ = ctx // reserved for future cancellation/timeouts inside client

	prompt := fmt.Sprintf(
		types.SplitTextWithContextPrompt,
		types.GetStandardLanguageName(targetLang),
		strings.TrimSpace(previousSentences),
		strings.TrimSpace(targetSentence),
		strings.TrimSpace(nextSentences),
		types.GetStandardLanguageName(targetLang),
	)

	text, model, err := s.chatCompletionWithFallback(prompt)
	if err != nil {
		return "", "", err
	}
	text = strings.TrimSpace(text)
	if text == "" {
		return "", model, fmt.Errorf("empty_response")
	}
	return text, model, nil
}

