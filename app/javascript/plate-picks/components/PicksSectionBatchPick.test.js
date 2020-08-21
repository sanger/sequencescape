import { shallowMount } from '@vue/test-utils'
import '@testing-library/jest-dom'
import PicksSectionBatchPick from './PicksSectionBatchPick.vue'
import defaultState from '../store/state'

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
          state: defaultState(),
          getters: { }
        }
      }
    })
    expect(wrapper.text()).toContain(name)
  })
})
