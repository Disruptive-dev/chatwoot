import {
  ACTIVE_INTERNAL_COMMANDS,
  getInternalCommandById,
  getInternalCommandPattern,
} from './registry';

const DOCUMENTOS_INVOCATION_REGEX = /(?:^|\s)@documentos(?:\s+([^\n@]*))?/gi;
const DOCUMENTOS_BARE_END_REGEX = /(?:^|\s)@documentos\s*$/i;
const DOCUMENTOS_WITH_TERM_REGEX = /(?:^|\s)@documentos\s+\S+/i;
const DOCUMENTOS_TRAILING_SPACE_REGEX = /(?:^|\s)@documentos\s+$/i;
const DOCUMENTOS_PARSE_REGEX = /(?:^|\s)@documentos(?:\s+([^\n@]*))?/i;

export const parseDocumentosInvocation = text => {
  if (!text) return null;

  const match = String(text).match(DOCUMENTOS_PARSE_REGEX);
  if (!match) return null;

  const searchTerm = String(match[1] || '').trim();

  return {
    id: 'documentos',
    searchTerm,
    raw: searchTerm ? `@documentos ${searchTerm}` : '@documentos',
  };
};

export const shouldOpenDocumentosModal = (text, { allowBare = false } = {}) => {
  const parsed = parseDocumentosInvocation(text);
  if (!parsed) return false;

  if (parsed.searchTerm.length > 0) return true;
  if (DOCUMENTOS_TRAILING_SPACE_REGEX.test(text)) return true;
  if (allowBare && DOCUMENTOS_BARE_END_REGEX.test(text)) return true;

  return false;
};

export const stripInternalCommands = text => {
  if (!text) return text;

  let result = String(text).replace(DOCUMENTOS_INVOCATION_REGEX, '');

  ACTIVE_INTERNAL_COMMANDS.forEach(command => {
    if (command.id === 'documentos') return;
    result = result.replace(getInternalCommandPattern(command.trigger), '');
  });

  return result.replace(/\s{2,}/g, ' ').trim();
};

export const containsInternalCommand = text => {
  if (!text) return false;

  return (
    parseDocumentosInvocation(text) !== null ||
    ACTIVE_INTERNAL_COMMANDS.some(command => {
      if (command.id === 'documentos') return false;
      return getInternalCommandPattern(command.trigger).test(text);
    })
  );
};

export const detectTriggeredInternalCommand = text => {
  const parsed = parseDocumentosInvocation(text);
  if (parsed) return getInternalCommandById('documentos');

  return (
    ACTIVE_INTERNAL_COMMANDS.find(command => {
      if (command.id === 'documentos') return false;
      return getInternalCommandPattern(command.trigger).test(text);
    }) || null
  );
};

export const removeDocumentosInvocation = text => {
  if (!text) return text;
  return String(text).replace(DOCUMENTOS_INVOCATION_REGEX, '').trim();
};

export const removeInternalCommandFromText = (text, commandId) => {
  if (commandId === 'documentos') {
    return removeDocumentosInvocation(text);
  }

  const command = ACTIVE_INTERNAL_COMMANDS.find(item => item.id === commandId);
  if (!command || !text) return text;

  return text.replace(getInternalCommandPattern(command.trigger), '').trim();
};

export const documentosInvocationChanged = (nextText, previousText) => {
  const next = parseDocumentosInvocation(nextText);
  const prev = parseDocumentosInvocation(previousText || '');
  return (next?.raw || '') !== (prev?.raw || '');
};

export const hasDocumentosSearchTerm = text =>
  DOCUMENTOS_WITH_TERM_REGEX.test(text || '');
