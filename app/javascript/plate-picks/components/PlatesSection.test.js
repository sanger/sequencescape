// test('there is no I in team', () => {
//   expect('team').not.toMatch(/I/);
// });

import { shallowMount } from '@vue/test-utils'
import '@testing-library/jest-dom'
import PlatesSection from './PlatesSection.vue'

const extractTable = (table) => {
  return table.findAll('tr').wrappers.map((row) => {
    return row.findAll('td,th').wrappers.map(cell => cell.text())
  })
}

describe('PlatesSection.vue', () => {
  it('renders a list of plates', () => {
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: {
          state: {
            plates: [
              { barcode: 'DN12345R', status: 'Pick', picks: [{name: 'Example Pick 1 of 3'}] },
              { barcode: 'DN12346S', status: 'Pick', picks: [{name: 'Example Pick 1 of 3'}] }
            ]
          }
        }
      }
    })
    const tableBody = wrapper.find('tbody')
    expect(tableBody.findAll('tr').length).toBe(2)
    let tableContent = extractTable(tableBody)
    expect(tableContent).toEqual([
      ['DN12345R', 'Pick', 'Example Pick 1 of 3'],
      ['DN12346S', 'Pick', 'Example Pick 1 of 3']
    ])
  })

  it('triggers plate lookup', async () => {
    const mockStore = {
      state: { plates: [] },
      dispatch: jest.fn()
    }
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: mockStore
      }
    })

    const input = wrapper.find('#scan-plate')
    await input.setValue('DN12345R')
    await input.trigger('blur')

    expect(mockStore.dispatch).toHaveBeenCalledWith(
      'plateBarcodeScan', 'DN12345R')
  })

  it('ignores empty input', async () => {
    const mockStore = {
      state: { plates: [] },
      dispatch: jest.fn()
    }
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: mockStore
      }
    })

    const input = wrapper.find('#scan-plate')
    await input.setValue('   ')
    await input.trigger('blur')

    expect(mockStore.dispatch).not.toHaveBeenCalled()
  })
})
