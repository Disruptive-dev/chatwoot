export const INTERNAL_COMMAND_STATUS = {
  ACTIVE: 'active',
  PLANNED: 'planned',
};

export const INTERNAL_COMMANDS = {
  documentos: {
    id: 'documentos',
    trigger: '@documentos',
    status: INTERNAL_COMMAND_STATUS.ACTIVE,
  },
  crm: {
    id: 'crm',
    trigger: '@crm',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
  cliente: {
    id: 'cliente',
    trigger: '@cliente',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
  playbook: {
    id: 'playbook',
    trigger: '@playbook',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
  ia: {
    id: 'ia',
    trigger: '@ia',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
  resumen: {
    id: 'resumen',
    trigger: '@resumen',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
  cotizacion: {
    id: 'cotizacion',
    trigger: '@cotizacion',
    status: INTERNAL_COMMAND_STATUS.PLANNED,
  },
};

export const ACTIVE_INTERNAL_COMMANDS = Object.values(INTERNAL_COMMANDS).filter(
  command => command.status === INTERNAL_COMMAND_STATUS.ACTIVE
);

export const PLANNED_INTERNAL_COMMANDS = Object.values(
  INTERNAL_COMMANDS
).filter(command => command.status === INTERNAL_COMMAND_STATUS.PLANNED);

export const getInternalCommandById = id => INTERNAL_COMMANDS[id] || null;

export const getInternalCommandPattern = trigger => {
  const escaped = trigger.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`${escaped}\\b`, 'gi');
};

export const getActiveInternalCommandPatterns = () =>
  ACTIVE_INTERNAL_COMMANDS.map(command => ({
    ...command,
    pattern: getInternalCommandPattern(command.trigger),
  }));
