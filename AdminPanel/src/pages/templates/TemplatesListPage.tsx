import { useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Plus,
  Pencil,
  Copy,
  CheckCircle2,
  Trash2,
  Search,
  Filter,
} from 'lucide-react';
import Button from '../../components/ui/Button';
import Table, { type Column } from '../../components/ui/Table';
import Spinner from '../../components/ui/Spinner';
import ConfirmDialog from '../../components/ui/ConfirmDialog';
import TemplateStatusBadge from './components/TemplateStatusBadge';
import {
  useTemplates,
  useActivateTemplate,
  useCloneTemplate,
  useDeleteTemplate,
} from '../../hooks/useTemplates';
import { useToastContext } from '../../hooks/ToastContext';
import type {
  InsuranceType,
  TemplateListItem,
  TemplateStatus,
} from '../../types';
import { INSURANCE_TYPES, TEMPLATE_STATUSES } from '../../types';

type PendingAction =
  | { kind: 'activate'; template: TemplateListItem }
  | { kind: 'delete'; template: TemplateListItem }
  | null;

const PAGE_SIZE = 20;

export default function TemplatesListPage() {
  const navigate = useNavigate();
  const { addToast } = useToastContext();
  const [searchParams, setSearchParams] = useSearchParams();

  const companyName = searchParams.get('company') ?? '';
  const insuranceType = (searchParams.get('type') as InsuranceType | null) ?? undefined;
  const status = (searchParams.get('status') as TemplateStatus | null) ?? undefined;
  const nameSearch = searchParams.get('q') ?? '';
  const pageNumber = Number(searchParams.get('page') ?? '1');

  const { data, isLoading, isFetching } = useTemplates({
    companyName: companyName || undefined,
    insuranceType,
    status,
    pageNumber,
    pageSize: PAGE_SIZE,
  });

  const activate = useActivateTemplate();
  const clone = useCloneTemplate();
  const del = useDeleteTemplate();

  const [pending, setPending] = useState<PendingAction>(null);

  // Backend pages by serverside filters; name search is applied client-side on the current page.
  const filteredItems = useMemo(() => {
    const items = data?.items ?? [];
    if (!nameSearch) return items;
    const q = nameSearch.toLowerCase();
    return items.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.companyName.toLowerCase().includes(q),
    );
  }, [data?.items, nameSearch]);

  const updateParam = (key: string, value: string) => {
    const next = new URLSearchParams(searchParams);
    if (value) next.set(key, value);
    else next.delete(key);
    if (key !== 'page') next.delete('page');
    setSearchParams(next);
  };

  const resetFilters = () => setSearchParams(new URLSearchParams());

  const goToPage = (page: number) => {
    const next = new URLSearchParams(searchParams);
    next.set('page', String(page));
    setSearchParams(next);
  };

  const handleClone = (t: TemplateListItem) => {
    clone.mutate(t.id, {
      onSuccess: (newTpl) => {
        addToast(`Cloned to v${newTpl.version} draft`, 'success');
        navigate(`/templates/${newTpl.id}/edit`);
      },
      onError: () => addToast('Failed to clone template', 'error'),
    });
  };

  const handleActivate = () => {
    if (pending?.kind !== 'activate') return;
    const id = pending.template.id;
    activate.mutate(id, {
      onSuccess: () => {
        addToast('Template activated', 'success');
        setPending(null);
      },
      onError: () => addToast('Failed to activate template', 'error'),
    });
  };

  const handleDelete = () => {
    if (pending?.kind !== 'delete') return;
    const id = pending.template.id;
    del.mutate(id, {
      onSuccess: () => {
        addToast('Template deleted', 'success');
        setPending(null);
      },
      onError: () => addToast('Failed to delete template', 'error'),
    });
  };

  const columns: Column<TemplateListItem>[] = [
    { key: 'name', header: 'Template Name', sortable: true },
    {
      key: 'insuranceType',
      header: 'Type',
      sortable: true,
      render: (r) => <span className="font-medium">{r.insuranceType}</span>,
    },
    {
      key: 'companyName',
      header: 'Company',
      sortable: true,
      render: (r) => <span>{r.companyName || '—'}</span>,
    },
    {
      key: 'version',
      header: 'Version',
      sortable: true,
      render: (r) => <span className="font-mono text-xs">v{r.version}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (r) => <TemplateStatusBadge status={r.status} />,
    },
    {
      key: 'updatedAt',
      header: 'Updated',
      render: (r) => (
        <span className="text-gray-500 text-xs">
          {r.updatedAt ? new Date(r.updatedAt).toLocaleDateString() : '—'}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (r) => (
        <div
          className="flex items-center gap-1"
          onClick={(e) => e.stopPropagation()}
        >
          <IconBtn
            title="Edit"
            onClick={() => navigate(`/templates/${r.id}/edit`)}
            icon={<Pencil size={16} />}
          />
          <IconBtn
            title="Clone to new draft"
            onClick={() => handleClone(r)}
            icon={<Copy size={16} />}
            loading={clone.isPending && clone.variables === r.id}
          />
          {r.status === 'Draft' && (
            <IconBtn
              title="Activate"
              onClick={() => setPending({ kind: 'activate', template: r })}
              icon={<CheckCircle2 size={16} />}
              variant="success"
            />
          )}
          <IconBtn
            title="Delete"
            onClick={() => setPending({ kind: 'delete', template: r })}
            icon={<Trash2 size={16} />}
            variant="danger"
          />
        </div>
      ),
    },
  ];

  const total = data?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-secondary">Templates</h1>
          <p className="text-sm text-gray-500">
            Define what the chatbot collects for each (company, insurance type).
          </p>
        </div>
        <Button onClick={() => navigate('/templates/new')}>
          <Plus size={16} />
          New Template
        </Button>
      </div>

      <div className="bg-card rounded-xl p-4 space-y-3">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex-1 min-w-[240px] relative">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <input
              type="text"
              value={nameSearch}
              onChange={(e) => updateParam('q', e.target.value)}
              placeholder="Search by name or company..."
              className="w-full pl-9 pr-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
            />
          </div>
          <input
            type="text"
            value={companyName}
            onChange={(e) => updateParam('company', e.target.value)}
            placeholder="Company"
            className="w-[200px] px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
          />
          <select
            value={insuranceType ?? ''}
            onChange={(e) => updateParam('type', e.target.value)}
            className="px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-white"
          >
            <option value="">All types</option>
            {INSURANCE_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
          <select
            value={status ?? ''}
            onChange={(e) => updateParam('status', e.target.value)}
            className="px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-white"
          >
            <option value="">All statuses</option>
            {TEMPLATE_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
          {(companyName || insuranceType || status || nameSearch) && (
            <button
              type="button"
              onClick={resetFilters}
              className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
            >
              <Filter size={14} /> Clear
            </button>
          )}
          {isFetching && !isLoading && <Spinner size="sm" />}
        </div>
      </div>

      <Table
        columns={columns}
        data={filteredItems}
        loading={isLoading}
        keyExtractor={(r) => r.id}
        onRowClick={(r) => navigate(`/templates/${r.id}/edit`)}
        emptyMessage={
          nameSearch || companyName || insuranceType || status
            ? 'No templates match the current filters.'
            : 'No templates yet. Click "New Template" to create one.'
        }
      />

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-600">
          <span>
            Page {pageNumber} of {totalPages} · {total} total
          </span>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={pageNumber <= 1}
              onClick={() => goToPage(pageNumber - 1)}
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={pageNumber >= totalPages}
              onClick={() => goToPage(pageNumber + 1)}
            >
              Next
            </Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={pending?.kind === 'activate'}
        onClose={() => setPending(null)}
        onConfirm={handleActivate}
        variant="success"
        title="Activate template"
        confirmLabel="Activate"
        loading={activate.isPending}
        message={
          pending?.kind === 'activate' ? (
            <>
              Activate <strong>{pending.template.name}</strong> (v{pending.template.version})?
              Any currently active template for <strong>{pending.template.companyName}</strong> /{' '}
              {pending.template.insuranceType} will be archived.
            </>
          ) : null
        }
      />

      <ConfirmDialog
        isOpen={pending?.kind === 'delete'}
        onClose={() => setPending(null)}
        onConfirm={handleDelete}
        variant="danger"
        title="Delete template"
        confirmLabel="Delete"
        loading={del.isPending}
        message={
          pending?.kind === 'delete' ? (
            <>
              Delete <strong>{pending.template.name}</strong> (v{pending.template.version})? This
              soft-deletes the draft and all its child settings.
            </>
          ) : null
        }
      />
    </div>
  );
}

function IconBtn({
  title,
  onClick,
  icon,
  variant = 'default',
  loading = false,
}: {
  title: string;
  onClick: () => void;
  icon: React.ReactNode;
  variant?: 'default' | 'success' | 'danger';
  loading?: boolean;
}) {
  const color =
    variant === 'success'
      ? 'text-green-700 hover:bg-success-light'
      : variant === 'danger'
        ? 'text-red-700 hover:bg-danger-light'
        : 'text-gray-500 hover:bg-gray-100';
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      disabled={loading}
      className={`p-1.5 rounded-lg transition-colors disabled:opacity-50 ${color}`}
    >
      {loading ? <Spinner size="sm" /> : icon}
    </button>
  );
}
