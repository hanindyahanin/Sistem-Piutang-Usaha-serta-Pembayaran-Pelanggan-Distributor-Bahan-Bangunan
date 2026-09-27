(function () {
  const SUPABASE_URL = 'https://upmbfawkextnjqtydqno.supabase.co';
  const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVwbWJmYXdrZXh0bmpxdHlkcW5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NzYwOTcsImV4cCI6MjEwNjA1MjA5N30.5fpzDrdDNcTT23Rbm-qe1s0D4NcS-4zFtnN1s-YftdI';

  if (typeof window !== 'undefined') {
    window.SUPABASE_CONFIG = window.SUPABASE_CONFIG || {
      supabaseUrl: SUPABASE_URL,
      supabaseKey: SUPABASE_KEY
    };
  }

  const invoicePolicy = {
    discountRate: 0.02,
    discountDays: 10,
    dueDays: 30,
    label: '2/10, n/30'
  };

  function formatCurrency(value) {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }

  function addDays(date, amount) {
    const newDate = new Date(date);
    newDate.setDate(newDate.getDate() + amount);
    return newDate;
  }

  function getDiscount(invoice, paymentDate) {
    if (!invoice || !paymentDate) return 0;
    const invoiceDate = new Date(invoice.invoiceDate || invoice.invoice_date);
    const paymentDay = new Date(paymentDate);
    const discountDeadline = addDays(invoiceDate, invoicePolicy.discountDays);

    if (paymentDay <= discountDeadline) {
      return Number(invoice.total || invoice.total_value) * invoicePolicy.discountRate;
    }

    return 0;
  }

  function getRemainingBalance(invoice, payments) {
    const totalInvoice = Number(invoice.total || invoice.total_value || 0);
    const totalPaid = (payments || []).reduce((sum, payment) => sum + Number(payment.amount || 0), 0);
    return Math.max(totalInvoice - totalPaid, 0);
  }

  function getInvoiceStatus(invoice, payments) {
    const remaining = getRemainingBalance(invoice, payments);
    if (remaining <= 0) return 'Lunas';
    if ((payments || []).length > 0) return 'Sebagian Dibayar';
    return 'Belum Dibayar';
  }

  function getAgingBucket(invoice, payments) {
    const remaining = getRemainingBalance(invoice, payments);
    if (remaining <= 0) return 'Lunas';

    const dueDate = new Date(invoice.dueDate || invoice.due_date);
    const today = new Date();
    const daysLate = Math.ceil((today - dueDate) / (1000 * 60 * 60 * 24));

    if (daysLate <= 0) return 'Aman';
    if (daysLate <= 30) return 'Waspada';
    if (daysLate <= 60) return 'Tidak Aman';
    return 'Overdue';
  }

  function createSupabaseClient() {
    if (typeof window === 'undefined') return null;

    if (!window.supabase) {
      console.warn('Supabase JS SDK belum termuat. Pastikan CDN Supabase sudah dimuat sebelum file ini.');
      return null;
    }

    const config = window.SUPABASE_CONFIG || { supabaseUrl: SUPABASE_URL, supabaseKey: SUPABASE_KEY };
    const { supabaseUrl, supabaseKey } = config;

    if (!supabaseUrl || !supabaseKey) {
      console.warn('URL atau anon key Supabase belum tersedia.');
      return null;
    }

    return window.supabase.createClient(supabaseUrl, supabaseKey);
  }

  async function fetchSupabaseData() {
    const supabaseClient = createSupabaseClient();
    if (!supabaseClient) return null;

    const [customersResult, invoicesResult, paymentsResult] = await Promise.all([
      supabaseClient.from('customers').select('*'),
      supabaseClient.from('invoices').select('*'),
      supabaseClient.from('payments').select('*')
    ]);

    return {
      customers: customersResult.data || [],
      invoices: invoicesResult.data || [],
      payments: paymentsResult.data || []
    };
  }

  async function insertPayment(payload) {
    const supabaseClient = createSupabaseClient();
    if (!supabaseClient) {
      console.warn('Supabase belum dikonfigurasi. Data hanya disimpan di memory browser.');
      return { ok: true, localOnly: true };
    }

    const { error } = await supabaseClient.from('payments').insert(payload);
    if (error) {
      console.error('Gagal insert pembayaran:', error);
      return { ok: false, error };
    }

    return { ok: true, localOnly: false };
  }

  window.SupabasePiutangApp = {
    policy: invoicePolicy,
    formatCurrency,
    getDiscount,
    getRemainingBalance,
    getInvoiceStatus,
    getAgingBucket,
    fetchSupabaseData,
    insertPayment,
    supabaseUrl: SUPABASE_URL,
    supabaseKey: SUPABASE_KEY
  };
})();
