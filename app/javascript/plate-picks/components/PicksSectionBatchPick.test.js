import { shallowMount } from '@vue/test-utils'
import '@testing-library/jest-dom'
import PicksSectionBatchPick from './PicksSectionBatchPick.vue'

describe('PicksSectionBatchPick.vue', () => {
  it('includes the name', () => {
    const name = 'Pick Name'
    const wrapper = shallowMount(PicksSectionBatchPick,{
      propsData: {
        name,
        id: '1',
        plates: []
      },
      mocks: {
        $store: {
          state: {},
          getters: { plateWithBarcode() { } }
        }
      }
    })
    expect(wrapper.text()).toContain(name)
  })
})
