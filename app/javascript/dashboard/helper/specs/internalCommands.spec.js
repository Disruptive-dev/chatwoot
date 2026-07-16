import {
  stripInternalCommands,
  parseDocumentosInvocation,
  shouldOpenDocumentosModal,
  removeDocumentosInvocation,
  documentosInvocationChanged,
  detectTriggeredInternalCommand,
  containsInternalCommand,
} from '../internalCommands';

describe('internalCommands', () => {
  it('detects @documentos command', () => {
    expect(parseDocumentosInvocation('Hola @documentos')).toEqual(
      expect.objectContaining({ id: 'documentos', searchTerm: '' })
    );
  });

  it('does not detect @documentos inside a word', () => {
    expect(parseDocumentosInvocation('foo@documentos')).toBeNull();
    expect(
      parseDocumentosInvocation('email@documentos presupuesto')
    ).toBeNull();
  });

  it('extracts initial search from @documentos presupuesto', () => {
    expect(parseDocumentosInvocation('@documentos presupuesto')).toEqual(
      expect.objectContaining({ searchTerm: 'presupuesto' })
    );
    expect(
      parseDocumentosInvocation('@documentos catálogo julio').searchTerm
    ).toBe('catálogo julio');
  });

  it('opens modal for search term immediately', () => {
    expect(shouldOpenDocumentosModal('@documentos contrato')).toBe(true);
    expect(shouldOpenDocumentosModal('@documentos', { allowBare: false })).toBe(
      false
    );
    expect(shouldOpenDocumentosModal('@documentos', { allowBare: true })).toBe(
      true
    );
  });

  it('does not detect planned commands', () => {
    expect(detectTriggeredInternalCommand('@crm')).toBeNull();
  });

  it('strips active internal commands before send', () => {
    expect(stripInternalCommands('Hola @documentos presupuesto')).toBe('Hola');
    expect(stripInternalCommands('Hola @documentos')).toBe('Hola');
    expect(containsInternalCommand('@documentos')).toBe(true);
    expect(stripInternalCommands('@documentos presupuesto')).toBe('');
  });

  it('removes full documentos invocation from text', () => {
    expect(removeDocumentosInvocation('Texto @documentos contrato')).toBe(
      'Texto'
    );
    expect(removeDocumentosInvocation('@documentos lista de precios')).toBe('');
  });

  it('detects invocation changes without duplicate modal triggers', () => {
    expect(
      documentosInvocationChanged('@documentos', '@documentos presupuesto')
    ).toBe(true);
    expect(
      documentosInvocationChanged(
        '@documentos presupuesto',
        '@documentos presupuesto'
      )
    ).toBe(false);
  });

  it('detects when message still contains internal commands', () => {
    expect(containsInternalCommand('@documentos')).toBe(true);
    expect(containsInternalCommand('mensaje normal')).toBe(false);
  });

  it('preserves UTF-8 in search terms', () => {
    const parsed = parseDocumentosInvocation('@documentos catálogo ñ');
    expect(parsed.searchTerm).toBe('catálogo ñ');
    expect(parsed.searchTerm).not.toMatch(/Ã|Â|�/);
  });
});
