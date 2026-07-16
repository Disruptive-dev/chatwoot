<script>
import { debounce } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { vOnClickOutside } from '@vueuse/components';
import SpectraDocumentsAPI from 'dashboard/api/spectra/documents';

export default {
  name: 'DocumentCommandModal',
  directives: {
    OnClickOutside: vOnClickOutside,
  },
  props: {
    initialSearch: {
      type: String,
      default: '',
    },
  },
  emits: ['close', 'select'],
  data() {
    return {
      searchQuery: '',
      isLoading: false,
      isAttaching: false,
      documents: [],
      debouncedSearch: () => {},
    };
  },
  computed: {
    filteredDocuments() {
      const query = this.searchQuery.trim().toLowerCase();
      if (!query) return this.documents;

      return this.documents.filter(document => {
        const title = String(
          document.title || document.file_name || ''
        ).toLowerCase();
        const category = String(document.source_category || '').toLowerCase();
        const tags = Array.isArray(document.tags)
          ? document.tags.join(' ').toLowerCase()
          : '';

        return (
          title.includes(query) ||
          category.includes(query) ||
          tags.includes(query)
        );
      });
    },
  },
  mounted() {
    this.searchQuery = this.initialSearch || '';
    this.debouncedSearch = debounce(this.fetchDocuments, 300, false);
    this.fetchDocuments();
  },
  methods: {
    onClose() {
      if (this.isAttaching) return;
      this.$emit('close');
    },
    onSearchInput(event) {
      this.searchQuery = event.target.value;
      this.debouncedSearch();
    },
    resolveLoadError(error) {
      const status = error?.response?.status;
      const message = error?.response?.data?.error;

      if (status === 401) {
        return this.$t(
          'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_CONNECT'
        );
      }
      if (status === 403) {
        return (
          message ||
          this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_FORBIDDEN')
        );
      }
      if ([502, 503, 504].includes(status)) {
        return this.$t(
          'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_CONNECT'
        );
      }
      return (
        message ||
        this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_CONNECT')
      );
    },
    resolveAttachError(error) {
      const status = error?.response?.status;
      const message = error?.response?.data?.error;

      if (status === 403) {
        if (message && /expir/i.test(message)) {
          return this.$t(
            'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_TOKEN_EXPIRED'
          );
        }
        return (
          message ||
          this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_FORBIDDEN')
        );
      }
      if (status === 404) {
        return this.$t(
          'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_NOT_FOUND'
        );
      }
      if (status === 409) {
        return (
          message ||
          this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_NOT_FOUND')
        );
      }
      if (status === 422) {
        if (message && /tamaño|size|large/i.test(message)) {
          return this.$t(
            'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_FILE_TOO_LARGE'
          );
        }
        return (
          message ||
          this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_ATTACH')
        );
      }
      if ([502, 503, 504].includes(status)) {
        return this.$t(
          'CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_CONNECT'
        );
      }
      return (
        message ||
        this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ERROR_ATTACH')
      );
    },
    async fetchDocuments() {
      try {
        this.isLoading = true;
        const { data } = await SpectraDocumentsAPI.getSendable({
          q: this.searchQuery.trim(),
        });
        this.documents = data.items || [];
      } catch (error) {
        useAlert(this.resolveLoadError(error));
        this.documents = [];
      } finally {
        this.isLoading = false;
      }
    },
    formatTags(tags) {
      if (!Array.isArray(tags) || tags.length === 0) {
        return this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.NO_TAGS');
      }

      return tags.join(', ');
    },
    formatFileSize(bytes) {
      const size = Number(bytes);
      if (!size || size <= 0) return '';

      if (size >= 1024 * 1024) {
        return `${(size / (1024 * 1024)).toFixed(1)} MB`;
      }

      return `${Math.max(Math.round(size / 1024), 1)} KB`;
    },
    formatStatus(document) {
      if (document.ready_for_send) {
        return this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.STATUS_READY');
      }

      return '—';
    },
    resolveFileName(document) {
      return (
        document.file_name ||
        document.title ||
        this.$t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.DEFAULT_FILENAME')
      );
    },
    async onSelectDocument(document) {
      if (this.isAttaching) return;

      try {
        this.isAttaching = true;
        const { data: tokenData } =
          await SpectraDocumentsAPI.createDownloadToken(document.id);
        const response = await SpectraDocumentsAPI.downloadDocument(
          document.id,
          tokenData.token
        );

        const blob = response.data;
        const fileName = this.resolveFileName(document);
        const mimeType =
          document.mime_type || blob.type || 'application/octet-stream';
        const file = new File([blob], fileName, { type: mimeType });

        this.$emit('select', {
          file: {
            name: fileName,
            type: mimeType,
            size: file.size,
            file,
          },
          document,
        });
        this.onClose();
      } catch (error) {
        useAlert(this.resolveAttachError(error));
      } finally {
        this.isAttaching = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="fixed top-0 left-0 z-50 flex items-center justify-center w-screen h-screen bg-modal-backdrop-light dark:bg-modal-backdrop-dark"
    data-testid="document-command-modal"
  >
    <div
      v-on-clickaway="onClose"
      class="flex flex-col px-4 pb-4 rounded-md shadow-md border border-solid border-n-weak bg-n-background z-[1000] max-w-[720px] md:w-[20rem] lg:w-[24rem] xl:w-[28rem] 2xl:w-[32rem] h-[calc(100vh-20rem)] max-h-[40rem]"
    >
      <div class="py-4 border-b border-n-weak">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.TITLE') }}
        </h3>
        <p class="text-[11px] text-n-slate-11 mt-1">
          {{ $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.SPECTRA_HINT') }}
        </p>
      </div>

      <div class="flex items-center justify-end pb-2">
        <button
          type="button"
          class="text-n-slate-11 hover:text-n-slate-12 text-sm"
          :disabled="isAttaching"
          @click="onClose"
        >
          {{ $t('CONVERSATION.INTERNAL_COMMANDS.CLOSE') }}
        </button>
      </div>

      <div class="py-3">
        <input
          type="search"
          class="w-full px-3 py-2 text-sm border rounded-md border-n-weak bg-n-solid-1 text-n-slate-12"
          :placeholder="
            $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.SEARCH_PLACEHOLDER')
          "
          :value="searchQuery"
          @input="onSearchInput"
        />
      </div>

      <div class="flex-1 overflow-y-auto">
        <div v-if="isLoading" class="py-8 text-sm text-center text-n-slate-11">
          {{ $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.LOADING') }}
        </div>

        <div
          v-else-if="filteredDocuments.length === 0"
          class="py-8 text-sm text-center text-n-slate-11"
        >
          {{ $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.EMPTY') }}
        </div>

        <button
          v-for="document in filteredDocuments"
          :key="document.id"
          type="button"
          class="w-full px-3 py-3 mb-2 text-left border rounded-md border-n-weak hover:bg-n-alpha-1 disabled:opacity-60"
          :disabled="isAttaching"
          @click="onSelectDocument(document)"
        >
          <p class="text-sm font-medium text-n-slate-12">
            {{ document.title || document.file_name }}
          </p>
          <p class="mt-1 text-xs text-n-slate-11">
            {{
              $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.CATEGORY', {
                category: document.source_category || '—',
              })
            }}
          </p>
          <p class="mt-1 text-xs text-n-slate-11">
            {{
              $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.TAGS', {
                tags: formatTags(document.tags),
              })
            }}
          </p>
          <p
            v-if="document.document_version"
            class="mt-1 text-xs text-n-slate-11"
          >
            {{
              $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.VERSION', {
                version: document.document_version,
              })
            }}
          </p>
          <p
            v-if="document.file_size_bytes || document.byte_size"
            class="mt-1 text-xs text-n-slate-11"
          >
            {{
              $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.SIZE', {
                size: formatFileSize(
                  document.file_size_bytes || document.byte_size
                ),
              })
            }}
          </p>
          <p class="mt-1 text-xs text-n-slate-11">
            {{
              $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.STATUS', {
                status: formatStatus(document),
              })
            }}
          </p>
        </button>
      </div>

      <p v-if="isAttaching" class="pt-2 text-xs text-center text-n-slate-11">
        {{ $t('CONVERSATION.INTERNAL_COMMANDS.DOCUMENTS.ATTACHING') }}
      </p>
    </div>
  </div>
</template>
