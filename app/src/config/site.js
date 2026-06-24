export const calendlyUrl = process.env.REACT_APP_CALENDLY_URL?.trim() || '';

export const hasCalendly = Boolean(calendlyUrl);

export const aiChatEndpoint = process.env.REACT_APP_AI_CHAT_ENDPOINT?.trim() || '';

export const hasAiChat = Boolean(aiChatEndpoint);
