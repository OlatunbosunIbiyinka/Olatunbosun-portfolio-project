import { fallbackResponse, intents, phraseIntents } from '../data/assistantKnowledge';
import { aiChatEndpoint } from '../config/site';

const normalize = (text) => text.toLowerCase().replace(/[^\w\s/]/g, ' ').replace(/\s+/g, ' ').trim();

function matchesPhrase(query, phrase) {
  return query.includes(phrase.toLowerCase());
}

function keywordMatches(query, keyword) {
  const pattern = keyword
    .toLowerCase()
    .split(/\s+/)
    .map((word) => word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('\\s+');
  return new RegExp(`\\b${pattern}\\b`, 'i').test(query);
}

export function getLocalResponse(message) {
  const query = normalize(message);

  // Phrase matches first (longest / most specific phrases checked first)
  for (const { phrases, response } of phraseIntents) {
    const sorted = [...phrases].sort((a, b) => b.length - a.length);
    if (sorted.some((phrase) => matchesPhrase(query, phrase))) {
      return response;
    }
  }

  let bestMatch = null;
  let bestScore = 0;

  for (const intent of intents) {
    const score = intent.keywords.reduce((total, keyword) => {
      if (!keywordMatches(query, keyword)) return total;
      return total + keyword.split(/\s+/).length;
    }, 0);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = intent;
    }
  }

  return bestScore > 0 ? bestMatch.response : fallbackResponse;
}

export async function askAssistant(message, history = []) {
  if (aiChatEndpoint) {
    try {
      const response = await fetch(aiChatEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message, history }),
      });

      if (response.ok) {
        const data = await response.json();
        const reply = data.reply || data.message || data.content;
        if (reply) return reply;
      }
    } catch {
      // Fall back to local knowledge when the endpoint is unavailable.
    }
  }

  await new Promise((resolve) => setTimeout(resolve, 400));
  return getLocalResponse(message);
}
