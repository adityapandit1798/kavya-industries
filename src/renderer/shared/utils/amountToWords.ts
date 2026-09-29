const ONES = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen'
];

const TENS = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
];

function convertHundreds(num: number): string {
  if (num === 0) return '';
  if (num < 20) return ONES[num];
  if (num < 100) {
    const tens = Math.floor(num / 10);
    const ones = num % 10;
    return TENS[tens] + (ones ? ' ' + ONES[ones] : '');
  }
  const hundreds = Math.floor(num / 100);
  const remainder = num % 100;
  return ONES[hundreds] + ' Hundred' + (remainder ? ' ' + convertHundreds(remainder) : '');
}

function convertToIndianWords(num: number): string {
  if (num === 0) return 'Zero';

  const isNegative = num < 0;
  num = Math.abs(Math.round(num));

  const crore = Math.floor(num / 10000000);
  const lakh = Math.floor((num % 10000000) / 100000);
  const thousand = Math.floor((num % 100000) / 1000);
  const hundred = num % 1000;

  let result = '';

  if (crore > 0) {
    result += convertHundreds(crore) + ' Crore';
  }
  if (lakh > 0) {
    result += (result ? ' ' : '') + convertHundreds(lakh) + ' Lakh';
  }
  if (thousand > 0) {
    result += (result ? ' ' : '') + convertHundreds(thousand) + ' Thousand';
  }
  if (hundred > 0) {
    result += (result ? ' ' : '') + convertHundreds(hundred);
  }

  if (isNegative) {
    result = 'Minus ' + result;
  }

  return result;
}

export function amountToIndianWords(amountInCents: number, currencyCode: string = 'INR'): string {
  if (!amountInCents || amountInCents === 0) {
    return `Rupees Zero Only`;
  }

  const isNegative = amountInCents < 0;
  const absAmount = Math.abs(amountInCents);

  const totalRupees = Math.floor(absAmount / 100);
  const paise = absAmount % 100;

  const rupeesWords = convertToIndianWords(totalRupees);
  const paiseWords = convertToIndianWords(paise);

  let result = `Rupees ${rupeesWords}`;

  if (paise > 0) {
    result += ` and ${paiseWords} Paise`;
  }

  result += ' Only';

  if (isNegative) {
    result = `Minus ${result}`;
  }

  return result.toUpperCase();
}
